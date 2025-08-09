class NoticeDecorator < Draper::Decorator
  decorates_association :backtrace
  delegate_all

  def backtrace_lines
    @backtrace_lines ||= object.backtrace_lines.map { |line| BacktraceLineDecorator.new(line) }
  end
end
