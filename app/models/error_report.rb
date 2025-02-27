require 'hoptoad_notifier'

GUID_PATTERN    = /\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b/
DOMAIN_PATTERN  = /\b[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+\b/
IP_PATTERN      = /\b(?:\d{1,3}\.){3}\d{1,3}\b/
INTEGER_PATTERN = /\b\d+\b/

VARIABLE_REGEX = Regexp.union(
  GUID_PATTERN,
  DOMAIN_PATTERN,
  IP_PATTERN,
  INTEGER_PATTERN
)

##
# Processes a new error report.
#
# Accepts a hash with the following attributes:
#
# * <tt>:error_class</tt> - the class of error
# * <tt>:message</tt> - the error message
# * <tt>:backtrace</tt> - an array of stack trace lines
#
# * <tt>:request</tt> - a hash of values describing the request
# * <tt>:server_environment</tt> - a hash of values describing the server environment
#
# * <tt>:notifier</tt> - information to identify the source of the error report
#
class ErrorReport
  attr_reader :api_key
  attr_reader :error_class
  attr_reader :framework
  attr_reader :message
  attr_reader :notice
  attr_reader :notifier
  attr_reader :problem
  attr_reader :problem_was_resolved
  attr_reader :request
  attr_reader :server_environment
  attr_reader :user_attributes

  def initialize(xml_or_attributes)
    @attributes = xml_or_attributes
    @attributes = Hoptoad.parse_xml!(@attributes) if @attributes.is_a? String
    @attributes = @attributes.with_indifferent_access
    @attributes.each { |k, v| instance_variable_set(:"@#{k}", v) }
  end

  def rails_env
    rails_env = server_environment['environment-name']
    rails_env = 'development' if rails_env.blank?
    rails_env
  end

  def app
    @app ||= App.where(api_key: api_key).first
  end

  def backtrace
    @normalized_backtrace ||= Backtrace.find_or_create(@backtrace)
  end

  def generate_notice!
    return unless valid?
    return @notice if @notice

    make_notice
    merge_problems

    notice.err_id = error.id
    notice.save!

    retrieve_problem_was_resolved
    cache_attributes_on_problem
    email_notification
    services_notification
    @notice
  end

  def make_notice
    @notice = Notice.new(
      app:                app,
      message:            message,
      error_class:        error_class,
      backtrace:          backtrace,
      request:            request,
      server_environment: server_environment,
      notifier:           notifier,
      user_attributes:    user_attributes,
      framework:          framework
    )
  end

  def retrieve_problem_was_resolved
    @problem_was_resolved = Problem.where('_id' => @error.problem_id, resolved: true).exists?
  end

  def merge_problems
    # Using rules to merge problems
    merge_rules = app.rules
    merge_rules.each do |rule|
      next unless rule.matches?(@notice)

      problems = find_problems_matching_rule(rule)
      next if problems.empty?

      @problem = if problems.count == 1
        problems.first
      else
        ProblemMerge.new(problems).merge
      end
      @error = @problem.errs.create!(error_attributes.slice(:fingerprint, :problem_id))
      break
    end

    return if @problem.present?

    # binding.pry
    # Using similar problems to merge
    similar_problems = find_similar_problems(@notice)
    return if similar_problems.empty?

    @problem = if similar_problems.count == 1
      similar_problems.first
    else
      ProblemMerge.new(similar_problems).merge
    end
    @error = @problem.errs.create!(error_attributes.slice(:fingerprint, :problem_id))
  end

  # Update problem cache with information about this notice
  def cache_attributes_on_problem
    @problem = Problem.cache_notice(@error.problem_id, @notice)
  end

  def should_email?
    problem_was_resolved ||
      app.email_at_notices.include?(0) ||
      app.email_at_notices.include?(@problem.notices_count)
  end

  # Send email notification if needed
  def email_notification
    return unless app.emailable? && should_email?
    Mailer.err_notification(self).deliver_now
  rescue => e
    HoptoadNotifier.notify(e)
  end

  def should_notify?
    problem_was_resolved ||
      app.notification_service.notify_at_notices.include?(0) ||
      app.notification_service.notify_at_notices.include?(@problem.notices_count)
  end

  # Launch all notification define on the app associate to this notice
  def services_notification
    return unless app.notification_service_configured? && should_notify?
    app.notification_service.create_notification(problem)
  rescue => e
    HoptoadNotifier.notify(e)
  end

  ##
  # Error associate to this error_report
  #
  # Can already exist or not
  #
  # @return [ Error ]
  def error
    @error ||= app.find_or_create_err!(error_attributes)
  end

  def error_attributes
    {
      error_class: error_class,
      environment: rails_env,
      fingerprint: fingerprint
    }
  end

  def valid?
    app.present?
  end

  def should_keep?
    app_version = server_environment['app-version'] || ''
    current_version = app.current_app_version
    return true unless current_version.present?
    return false if app_version.length <= 0
    Gem::Version.new(app_version) >= Gem::Version.new(current_version)
  end

  def fingerprint
    app.notice_fingerprinter.generate(api_key, notice, backtrace)
  end

  def find_problems_matching_rule(rule)
    Problem.where(message: /#{Regexp.escape(rule.condition)}/i).order(created_at: :asc)
  end

  def find_similar_problems(notice)
    Problem.where(message: /#{text_to_regex_string(notice.message)}/i).order(created_at: :asc)
  end

  def text_to_regex_string(input_str)
    result = +""  # mutable string
    last_pos = 0
  
    input_str.scan(VARIABLE_REGEX) do
      match = Regexp.last_match
      match_start = match.begin(0)
      match_end   = match.end(0)
      variable_text = match[0]
  
      # Add the literal (escaped) text up to the start of this match
      literal_text = input_str[last_pos...match_start]
      result << Regexp.escape(literal_text)
  
      # Decide which pattern to insert for this match
      case variable_text
      when GUID_PATTERN
        # Insert unescaped GUID pattern
        result << '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
      when DOMAIN_PATTERN
        # Insert unescaped domain pattern
        result << '[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+'
      when IP_PATTERN
        # Insert unescaped IP pattern
        result << '(?:\d{1,3}\.){3}\d{1,3}'
      when INTEGER_PATTERN
        # Insert unescaped integer pattern
        result << '\d+'
      else
        # Fallback: if for some reason we matched something else, just escape it
        result << Regexp.escape(variable_text)
      end
  
      last_pos = match_end
    end
  
    # Add any leftover text after the final match
    leftover = input_str[last_pos..-1]
    result << Regexp.escape(leftover) if leftover
  
    result
  end
end
