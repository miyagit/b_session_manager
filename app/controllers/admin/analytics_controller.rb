class Admin::AnalyticsController < Admin::BaseController
  # GET /admin/analytics
  def show
    @axis = params[:axis].presence_in(ResultSummary::AXES.keys) || "staff"
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    range = @axis == "month" ? (@month << 5)..@month.end_of_month : @month..@month.end_of_month
    @rows = ResultSummary.build(WorkSession.with_results.where(work_date: range), axis: @axis)
  end

  private
    def parse_month(value)
      Date.strptime(value, "%Y-%m") if value.present?
    rescue Date::Error
      nil
    end
end
