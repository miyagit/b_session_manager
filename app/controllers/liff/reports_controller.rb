class Liff::ReportsController < Liff::BaseController
  before_action :require_staff
  before_action :set_work_sessions, only: %i[ new create ]

  # GET /liff/reports/new
  # Shows the form straight away when the staff member has a single booth; otherwise lets them pick one.
  def new
    @work_session = @work_sessions.find { |work_session| work_session.id.to_s == params[:work_session_id] }
    @work_session ||= @work_sessions.first if @work_sessions.one?
    return unless @work_session

    registered_slots = @work_session.reports.map(&:report_slot)
    @report = Report.new(work_session: @work_session, submitted_by: current_staff)
    @report.report_slot = (Report::SLOTS - registered_slots).first
    @report.report_type = @report.report_slot == Report::SLOTS.last ? :final : :interim
    build_result_rows
  end

  # POST /liff/reports
  def create
    @work_session = @work_sessions.find { |work_session| work_session.id.to_s == report_params[:work_session_id] }
    return redirect_to new_liff_report_path, alert: "この稼働予定には報告できません。" unless @work_session

    @report = Report.new(report_params.except(:work_session_id)
      .merge(work_session: @work_session, submitted_by: current_staff, reported_at: Time.current))

    if @report.save
      redirect_to liff_report_path(@report), notice: "実績を報告しました。"
    else
      build_result_rows
      render :new, status: :unprocessable_content
    end
  end

  # GET /liff/reports/1
  def show
    @report = current_staff.submitted_reports.includes(work_session: :work_location, report_results: { work_assignment: :user })
      .find(params.expect(:id))
  end

  private
    # Booths the staff member is assigned to today, plus yesterday for a final report filed after midnight.
    def set_work_sessions
      @work_sessions = WorkSession.where(id: current_staff.work_assignments.select(:work_session_id), work_date: Date.yesterday..Date.current)
        .includes(:work_location, :reports, work_assignments: :user).order(work_date: :desc, id: :asc).to_a
    end

    def report_params
      params.expect(report: [ :work_session_id, :report_type, :report_slot,
                              report_results_attributes: [ [ :work_assignment_id, :acquired_count, :approach_count, :card_count ] ] ])
    end

    # The reporting staff member's own row comes first.
    def build_result_rows
      work_assignments = @work_session.work_assignments.sort_by { |work_assignment| [ work_assignment.user_id == current_staff.id ? 0 : 1, work_assignment.id ] }
      @result_rows = @report.result_rows_for(work_assignments)
    end
end
