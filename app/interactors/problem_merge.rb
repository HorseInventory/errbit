require 'problem_destroy'

class ProblemMerge
  def initialize(*problems)
    problems = problems.flatten.uniq
    @merged_problem = problems[0]
    @child_problems = problems[1..-1]
  end

  def merge
    return merged_problem if child_problems.empty?

    Notice.where(
      :problem_id.in => child_problems.map(&:id),
    ).update_all(problem_id: merged_problem.id)

    ProblemDestroy.new(child_problems).execute

    merged_problem
  end

private

  attr_reader :merged_problem, :child_problems
end
