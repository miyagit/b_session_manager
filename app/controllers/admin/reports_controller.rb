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

  # GET /admin/reports/new
  # Without work_session_id this lists the day's work sessions to pick from; with it, it shows the entry form.
  def new
    if params[:work_session_id].present?
      @work_session = find_work_session(params[:work_session_id])
      registered_slots = @work_session.reports.map(&:report_slot)
      @report = Report.new(work_session: @work_session, reported_at: Time.current,
                           submitted_by_id: @work_session.work_assignments.min_by(&:id)&.user_id)
      @report.report_slot = (Report::SLOTS - registered_slots).first
      @report.report_type = @report.report_slot == Report::SLOTS.last ? :final : :interim
      build_result_rows
    else
      @date = parse_date(params[:date]) || Date.current
      @work_sessions = WorkSession.includes(:work_location, :reports, work_assignments: :user)
        .where(work_date: @date).order(:work_location_id, :team_name)
    end
  end

  # POST /admin/reports
  def create
    @work_session = find_work_session(report_params[:work_session_id])
    @report = Report.new(report_params.except(:work_session_id).merge(work_session: @work_session))

    if @report.save
      redirect_to admin_report_path(@report), notice: "実績を登録しました。"
    else
      build_result_rows
      render :new, status: :unprocessable_content
    end
  end

  private
    def report_params
      params.expect(report: [ :work_session_id, :report_type, :report_slot, :reported_at, :submitted_by_id,
                              report_results_attributes: [ [ :work_assignment_id, :acquired_count, :approach_count, :card_count ] ] ])
    end

    def find_work_session(id)
      WorkSession.includes(:work_location, :reports, work_assignments: :user).find(id)
    end

    def build_result_rows
      @result_rows = @report.result_rows_for(@work_session.work_assignments.sort_by(&:id))
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
