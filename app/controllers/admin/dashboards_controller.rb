class Admin::DashboardsController < Admin::BaseController
  # GET /admin
  def show
    @date = Date.current
    base_work_sessions = WorkSession.includes(:work_location, :reports, work_assignments: [ :user, { report_results: :report } ])
    @work_sessions = base_work_sessions.includes(reports: :line_message_delivery)
      .where(work_date: @date).order(:work_location_id, :team_name)
    @month_sessions = base_work_sessions.where(work_date: @date.beginning_of_month..@date)
    @month_summary = ResultSummary.build(@month_sessions, axis: "month").first
    @staff_rows = ResultSummary.build(@work_sessions, axis: "staff").sort_by { |row| -row.acquired }
    @failed_deliveries = LineMessageDelivery.failed.includes(report: { work_session: :work_location }).order(created_at: :desc).limit(5)
  end
end
