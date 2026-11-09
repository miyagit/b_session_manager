class Liff::ReportsController < Liff::BaseController
  before_action :require_staff

  # GET /liff/reports/new
  # Without work_location_id this lists the booths with today's report status; with it, it shows the entry form.
  def new
    if params[:work_location_id].present?
      @work_location = WorkLocation.find(params[:work_location_id])
      @registered_reports = registered_reports_for(@work_location)
      @report = Report.new(work_location: @work_location, work_date: Date.current, submitted_by: current_staff)
      @report.report_slot = (Report::SLOTS - @registered_reports.map(&:report_slot)).first
      @report.report_type = @report.report_slot == Report::SLOTS.last ? :final : :interim
      build_result_rows
    else
      @work_locations = WorkLocation.order(:id).to_a
      @booth_days = BoothDay.build(Report.includes(:work_location, report_results: :user).where(work_date: Date.current))
        .index_by { |booth_day| booth_day.work_location.id }
    end
  end

  # POST /liff/reports
  def create
    @work_location = WorkLocation.find(report_params[:work_location_id])
    @report = Report.new(report_params.except(:work_location_id)
      .merge(work_location: @work_location, work_date: Date.current, submitted_by: current_staff, reported_at: Time.current))

    if @report.save
      redirect_to liff_report_path(@report), notice: "実績を報告しました。"
    else
      @registered_reports = registered_reports_for(@work_location)
      build_result_rows
      render :new, status: :unprocessable_content
    end
  end

  # GET /liff/reports/1
  def show
    @report = current_staff.submitted_reports.includes(:work_location, report_results: :user).find(params.expect(:id))
  end

  private
    def registered_reports_for(work_location)
      work_location.reports.where(work_date: Date.current).order(:report_slot).to_a
    end

    def report_params
      params.expect(report: [ :work_location_id, :report_type, :report_slot,
                              report_results_attributes: [ [ :user_id, :acquired_count, :approach_count, :card_count ] ] ])
    end

    # The reporting staff member's own row first, then rows for colleagues up to MAX_RESULTS in total.
    def build_result_rows
      own_row = @report.report_results.find { |report_result| report_result.user_id == current_staff.id } || @report.report_results.build(user: current_staff)
      other_rows = @report.report_results.reject { |report_result| report_result.equal?(own_row) }
      (Report::MAX_RESULTS - 1 - other_rows.size).times { other_rows << @report.report_results.build }
      @result_rows = [ own_row, *other_rows ]
    end
end
