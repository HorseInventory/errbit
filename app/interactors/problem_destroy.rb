class ProblemDestroy
  def initialize(problems)
    @problems = problems
  end

  def execute
    if @problems.respond_to?(:destroy_all)
      @problems.destroy_all
    else
      @problems.each(&:destroy)
    end

    # Delete all backtraces that are not associated with any notices
    Backtrace.where(:id.nin => Notice.pluck(:backtrace_id)).delete_all
  end
end
