class Admin::ReportsController < Admin::BaseController
  # GET /admin/reports
  def index
    @date = parse_date(params[:date]) || Date.current
    @reports = Report.includes(:work_location, :submitted_by, :line_message_delivery, report_results: :user)
      .where(work_date: @date).order(:work_location_id, :report_slot)
  end

  # GET /admin/reports/1
  def show
    @report = Report.includes(:work_location, :submitted_by, :line_message_delivery, report_results: :user).find(params.expect(:id))
  end

  # GET /admin/reports/new
  def new
    @report = Report.new(work_date: parse_date(params[:date]) || Date.current, reported_at: Time.current, report_type: :interim)
    build_result_rows
  end

  # POST /admin/reports
  def create
    @report = Report.new(report_params)

    if @report.save
      redirect_to admin_report_path(@report), notice: "実績を登録しました。"
    else
      build_result_rows
      render :new, status: :unprocessable_content
    end
  end

  private
    def report_params
      params.expect(report: [ :work_location_id, :work_date, :report_type, :report_slot, :reported_at, :submitted_by_id,
                              report_results_attributes: [ [ :user_id, :acquired_count, :approach_count, :card_count ] ] ])
    end

    # Always MAX_RESULTS rows: the ones already entered, then blank rows.
    def build_result_rows
      (Report::MAX_RESULTS - @report.report_results.size).times { @report.report_results.build }
      @result_rows = @report.report_results.to_a
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end
end
