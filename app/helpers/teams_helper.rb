# Number formats of the team progress screen.
module TeamsHelper
  # "4.5稼働"
  def format_units(value) = "#{format("%.1f", value)}稼働"

  # "42.0時間"
  def format_hours(value) = "#{format("%.1f", value)}時間"

  # "1,940件"
  def format_pieces(value) = value ? "#{number_with_delimiter(value)}件" : "—"

  # 獲得平均 (件/6時間): "31.5", or — when there are no hours to divide by.
  def format_average(value) = value ? format("%.1f", value) : "—"

  # 生産性 (件/時間): "5.26"
  def format_productivity(value) = value ? format("%.2f", value) : "—"

  # 本日時点の目標: "1,846.1件"
  def format_count(value) = value ? "#{number_with_delimiter(format("%.1f", value))}件" : "—"

  # 目標との差: "-1,411.1件", "+3.0件", "0.0件"
  def format_signed_count(value)
    return "—" if value.nil?

    "#{number_with_delimiter(format(value.zero? ? "%.1f" : "%+.1f", value))}件"
  end

  # ペース達成率: "64.8%"
  def format_rate_decimal(value) = value ? "#{format("%.1f", value)}%" : "—"

  # ペース判定: only a delay is called out, as on the team sheet.
  def pace_badge(row) = row.behind? ? status_badge("▼遅れ", :critical) : tag.span("—", class: "text-slate-400")
end
