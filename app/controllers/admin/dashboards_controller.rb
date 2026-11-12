class Admin::DashboardsController < Admin::BaseController
  # GET /admin
  def show
    @date = Date.current
    base_work_sessions = WorkSession.includes(:work_location, shifts: [ :user, :work_record ], reports: :report_results)
    @work_sessions = base_work_sessions.includes(reports: :line_message_delivery).where(work_date: @date).order(:work_location_id)
    @month_summary = ResultSummary.build(base_work_sessions.where(work_date: @date.beginning_of_month..@date), axis: "month").first
    @staff_rows = ResultSummary.build(@work_sessions, axis: "staff")
    @failed_deliveries = LineMessageDelivery.failed.includes(report: { work_session: :work_location }).order(created_at: :desc).limit(5)
  end
end
