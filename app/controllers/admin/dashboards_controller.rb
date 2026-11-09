class Admin::DashboardsController < Admin::BaseController
  # GET /admin
  def show
    @date = Date.current
    reports = Report.includes(:work_location, report_results: :user)
    today_reports = reports.includes(:line_message_delivery).where(work_date: @date)
    @booth_days = BoothDay.build(today_reports)
    @month_summary = ResultSummary.build(reports.where(work_date: @date.beginning_of_month..@date), axis: "month").first
    @staff_rows = ResultSummary.build(today_reports, axis: "staff")
    @failed_deliveries = LineMessageDelivery.failed.includes(report: :work_location).order(created_at: :desc).limit(5)
  end
end
