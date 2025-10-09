module ProblemSorting
  def sort_and_paginate_problems(problems, sort_by, order, page, per_page)
    if sort_by == 'last_notice_at'
      sorted = problems.to_a.sort_by do |problem|
        timestamp = problem.last_notice_at
        if order == 'asc'
          timestamp || Time.at(0)
        else
          timestamp ? -timestamp.to_i : -Time.at(0).to_i
        end
      end
      Kaminari.paginate_array(sorted).page(page).per(per_page)
    else
      problems.page(page).per(per_page)
    end
  end
end
