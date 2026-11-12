# Monthly staff rankings: total acquisitions, and acquisition averages per booth category (donki per 6 hours
# worked, cinema per 8-hour day). Both views rank everyone: 全員 shows every name, 上位5名のみ only the top five
# (6th place and below show ー).
class Admin::RankingsController < Admin::BaseController
  METRICS = { "total" => "総獲得件数", "donki" => "獲得平均（ドンキ・6時間あたり）", "cinema" => "獲得平均（シネマ・1日8時間あたり）" }.freeze
  TOP_COUNT = 5

  # GET /admin/rankings
  def index
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @metric = params[:metric].presence_in(METRICS.keys) || "total"
    @top_only = params[:top].present?

    work_sessions = WorkSession.includes(:work_location, shifts: [ :user, :work_record ], reports: :report_results).where(work_date: @month..@month.end_of_month)
    rows = ResultSummary.build(work_sessions, axis: "staff")
    @rows = case @metric
    when "donki" then rows.select { |row| row.donki_hours.positive? }.sort_by { |row| [ -row.donki_average, row.label ] }
    when "cinema" then rows.select { |row| row.cinema_hours.positive? }.sort_by { |row| [ -row.cinema_average, row.label ] }
    else rows.sort_by { |row| [ -row.acquired, row.label ] }
    end
  end

  private
    def parse_month(value)
      Date.strptime(value, "%Y-%m") if value.present?
    rescue Date::Error
      nil
    end
end
