class NoticesController < ApplicationController
  respond_to :json

  def index
    query = {}
    fields = ['created_at', 'message', 'error_class']

    if params.key?(:start_date) && params.key?(:end_date)
      start_date = Time.zone.parse(params[:start_date]).utc
      end_date = Time.zone.parse(params[:end_date]).utc
      query = { created_at: { "$lte" => end_date, "$gte" => start_date } }
    end

    problem = Problem.find(params[:problem_id])
    @notices = problem.notices.reverse_ordered.where(query).only(fields).page(params[:page]).per(50)

    respond_to do |format|
      format.json { render(json: @notices) }
    end
  end
end
