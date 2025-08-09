require 'problem_destroy'

class ProblemMerge
  def initialize(*problems)
    problems = problems.flatten.uniq
    @merged_problem = problems[0]
    @child_problems = problems[1..-1]
  end
  attr_reader :merged_problem, :child_problems

  def merge
    Notice.where(
      :problem_id.in => child_problems.map(&:id),
    ).update_all(problem_id: merged_problem.id)

    ProblemDestroy.new(child_problems).execute

    merged_problem
  end
end
