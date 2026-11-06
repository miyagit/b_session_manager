class Admin::ReportsController < Admin::BaseController
  # GET /admin/reports
  def index
    @date = parse_date(params[:date]) || Date.current
    @reports = Report.includes(:submitted_by, :line_message_delivery, report_results: { work_assignment: :user }, work_session: :work_location)
      .joins(:work_session).where(work_sessions: { work_date: @date })
      .order("work_sessions.work_location_id", "work_sessions.team_name", :report_slot)
  end

  # GET /admin/reports/1
  def show
    @report = Report.includes(:submitted_by, :line_message_delivery, report_results: { work_assignment: :user }, work_session: :work_location)
      .find(params.expect(:id))
  end

  private
    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
