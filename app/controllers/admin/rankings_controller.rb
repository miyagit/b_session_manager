# Monthly staff rankings per booth category (donki, which includes the event booths, and cinema): total acquisitions
# and the acquisition average (donki per 6 hours worked, cinema per 8-hour day). Each ranking covers the staff who
# worked that category in the month. Both views rank everyone: 全員 shows every name, 上位5名のみ only the top five
# (6th place and below show ー).
class Admin::RankingsController < Admin::BaseController
  METRICS = {
    "donki_total" => "ドンキの総獲得件数",
    "donki_average" => "ドンキの獲得平均（6時間あたり）",
    "cinema_total" => "シネマの総獲得件数",
    "cinema_average" => "シネマの獲得平均（1日8時間あたり）"
  }.freeze
  TOP_COUNT = 5

  # GET /admin/rankings
  def index
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @metric = params[:metric].presence_in(METRICS.keys) || METRICS.keys.first
    @top_only = params[:top].present?

    work_sessions = WorkSession.includes(:work_location, shifts: [ :user, :work_record ], reports: :report_results).where(work_date: @month..@month.end_of_month)
    rows = ResultSummary.build(work_sessions, axis: "staff")
    @rows = case @metric
    when "donki_total" then rows.select { |row| row.donki_hours.positive? }.sort_by { |row| [ -row.donki_acquired, row.label ] }
    when "donki_average" then rows.select { |row| row.donki_hours.positive? }.sort_by { |row| [ -row.donki_average, row.label ] }
    when "cinema_total" then rows.select { |row| row.cinema_hours.positive? }.sort_by { |row| [ -row.cinema_acquired, row.label ] }
    when "cinema_average" then rows.select { |row| row.cinema_hours.positive? }.sort_by { |row| [ -row.cinema_average, row.label ] }
    end
  end

  private
    def parse_month(value)
      Date.strptime(value, "%Y-%m") if value.present?
    rescue Date::Error
      nil
    end
end
