require 'problem_destroy'

class ProblemMerge
  MAX_RECENT_NOTICES = 100

  def initialize(*problems)
    problems = problems.flatten.uniq
    @merged_problem = problems[0]
    @child_problems = problems[1..-1]
  end
  attr_reader :merged_problem, :child_problems

  def merge
    child_problems.each do |problem|
      merged_problem.errs.concat problem.errs
      merged_problem.comments.concat problem.comments
      problem.reload # deference all associate objet to avoid delete him after
      ProblemDestroy.execute(problem)
    end

    # Keep only the MAX_RECENT_NOTICES most recent notices and related Errs
    deleted_count = trim_old_notices_and_errs

    # If we deleted, then we were at the limit so we just add whatever we deleted above the limit
    if deleted_count > 0
      cached_notices_count = merged_problem.notices_count
      merged_problem.notices_count = cached_notices_count + deleted_count
    else
      # If we didn't delete, then we can use the real count
      merged_problem.notices_count = notices.count
    end

    merged_problem.recache

    merged_problem
  end

  private

  def trim_old_notices_and_errs
    # Get count of all notices
    total_count = merged_problem.notices.count

    if total_count > MAX_RECENT_NOTICES
      # Get notices to keep (100 most recent)
      notices_to_keep = merged_problem.notices.reverse_ordered.limit(MAX_RECENT_NOTICES)
      notice_ids_to_keep = notices_to_keep.pluck(:id)

      # Delete notices that belong to errs we're keeping but aren't in our keep list
      merged_problem.notices.where(:id.nin => notice_ids_to_keep).delete

      # Delete errs and their associated notices we don't want to keep
      err_ids_to_keep = notices_to_keep.pluck(:err_id).uniq
      merged_problem.errs.where(:id.nin => err_ids_to_keep).delete

      total_count - MAX_RECENT_NOTICES
    else
      0
    end
  end
end
