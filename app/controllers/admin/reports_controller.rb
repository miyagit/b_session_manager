# Reports are normally filed by staff from LINE (Liff::ReportsController); new/create let an admin file one by hand.
class Admin::ReportsController < Admin::BaseController
  include ReportFiling

  # GET /admin/reports
  def index
    @date = parse_date(params[:date]) || Date.current
    @reports = Report.includes(:submitted_by, :line_message_delivery, report_results: :user, work_session: [ :work_location, shifts: :user ])
      .joins(:work_session).where(work_sessions: { work_date: @date })
      .order("work_sessions.work_location_id", Arel.sql("CASE report_type WHEN 'start' THEN 0 WHEN 'interim' THEN 1 ELSE 2 END"), :report_slot)
  end

  # GET /admin/reports/1
  def show
    @report = Report.includes(:submitted_by, :line_message_delivery, report_results: :user, work_session: [ :work_location, shifts: [ :user, :work_record ] ])
      .find(params.expect(:id))
  end

  # GET /admin/reports/new
  # Without work_session_id this lists the day's work sessions to pick from; with it, it shows the entry form.
  def new
    if params[:work_session_id].present?
      @work_session = find_work_session(params[:work_session_id])
      @report = Report.new(work_session: @work_session, submitted_by_id: @work_session.shifts.min_by(&:id)&.user_id)
      assign_default_report_type(@report, @work_session)
      @result_rows = build_result_rows(@report, @work_session)
    else
      @date = parse_date(params[:date]) || Date.current
      @work_sessions = WorkSession.includes(:work_location, shifts: :user, reports: :report_results)
        .where(work_date: @date).order(:work_location_id)
    end
  end

  # POST /admin/reports
  def create
    @work_session = find_work_session(report_params[:work_session_id])
    @report = Report.new(report_attributes_for_type(report_params).except(:work_session_id).merge(work_session: @work_session))
    assign_targets(@work_session) if @report.start?
    assign_work_records(@work_session) if @report.final?

    if save_report(@report, @work_session)
      redirect_to admin_report_path(@report), notice: "実績を登録しました。"
    else
      @result_rows = build_result_rows(@report, @work_session)
      render :new, status: :unprocessable_content
    end
  end

  private
    def find_work_session(id)
      WorkSession.includes(:work_location, shifts: [ :user, :work_record ], reports: :report_results).find(id)
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
