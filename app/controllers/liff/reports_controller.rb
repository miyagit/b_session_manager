class Liff::ReportsController < Liff::BaseController
  include ReportFiling

  before_action :require_staff
  before_action :set_work_sessions, only: %i[ new create ]

  # GET /liff/reports/new
  # The booth comes from the staff member's shift: the form opens directly for a single booth, otherwise they pick one.
  def new
    @work_session = @work_sessions.find { |work_session| work_session.id.to_s == params[:work_session_id] }
    open_work_sessions = @work_sessions.reject(&:all_reports_filed?)
    @work_session ||= open_work_sessions.first if open_work_sessions.one?
    return unless @work_session

    @report = Report.new(work_session: @work_session, submitted_by: current_staff)
    assign_default_report_type(@report, @work_session)
    @result_rows = build_result_rows(@report, @work_session, first_user_id: current_staff.id)
  end

  # POST /liff/reports
  def create
    @work_session = @work_sessions.find { |work_session| work_session.id.to_s == report_params[:work_session_id] }
    return redirect_to new_liff_report_path, alert: "この稼働予定には報告できません。" unless @work_session

    @report = Report.new(report_attributes_for_type(report_params).except(:work_session_id, :submitted_by_id)
      .merge(work_session: @work_session, submitted_by: current_staff))
    assign_targets(@work_session) if @report.start?

    if save_report(@report, @work_session)
      redirect_to liff_report_path(@report), notice: "実績を報告しました。"
    else
      @result_rows = build_result_rows(@report, @work_session, first_user_id: current_staff.id)
      render :new, status: :unprocessable_content
    end
  end

  # GET /liff/reports/1
  def show
    @report = current_staff.submitted_reports.includes(report_results: :user, work_session: [ :work_location, shifts: :user ]).find(params.expect(:id))
    @line_message = LineReportMessage.build(@report)
  end

  private
    # Booths the staff member has a shift on today, plus yesterday for a final report filed after midnight.
    def set_work_sessions
      @work_sessions = WorkSession.where(id: current_staff.shifts.select(:work_session_id), work_date: Date.yesterday..Date.current)
        .includes(:work_location, shifts: :user, reports: :report_results).order(work_date: :desc, id: :asc).to_a
    end
end
