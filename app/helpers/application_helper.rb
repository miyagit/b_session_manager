module ApplicationHelper
  BADGE_TONES = {
    good: "bg-good-bg text-good-text",
    warning: "bg-warning-bg text-warning-text",
    critical: "bg-critical-bg text-critical-text",
    info: "bg-blue-50 text-blue-700",
    neutral: "bg-slate-100 text-slate-600"
  }.freeze

  BADGE_DOTS = { good: "bg-good", warning: "bg-warning", critical: "bg-critical", info: "bg-blue-600", neutral: "bg-slate-400" }.freeze

  REPORT_TONES = { "start" => :info, "interim" => :warning, "final" => :good }.freeze

  # A pill with a colored dot; the label carries the meaning, the color only supports it.
  def status_badge(label, tone)
    tag.span(class: "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-semibold #{BADGE_TONES.fetch(tone)}") do
      tag.span(class: "size-1.5 rounded-full #{BADGE_DOTS.fetch(tone)}", aria: { hidden: true }) + label
    end
  end

  def result_status_badge(status)
    case status
    when :confirmed then status_badge("確定", :good)
    when :provisional then status_badge("暫定", :warning)
    else status_badge("報告なし", :neutral)
    end
  end

  def delivery_status_badge(delivery)
    case delivery&.status
    when "sent" then status_badge("投稿済み", :good)
    when "failed" then status_badge("投稿失敗", :critical)
    when "pending" then status_badge("送信待ち", :info)
    else status_badge("未投稿", :neutral)
    end
  end

  # "開始報告", "13時 途中報告" or "最終報告" as a badge.
  def report_badge(report)
    status_badge(report_badge_label(report), REPORT_TONES.fetch(report.report_type))
  end

  def report_badge_label(report)
    report.interim? ? "#{report.report_slot}時 途中報告" : Report.human_attribute_name("report_type.#{report.report_type}")
  end

  # "13時の途中報告", or the report type name, for headings.
  def report_heading(report)
    report.interim? ? "#{report.report_slot}時の途中報告" : Report.human_attribute_name("report_type.#{report.report_type}")
  end

  def shift_type_label(shift)
    Shift.human_attribute_name("shift_type.#{shift.shift_type}")
  end

  # "97%", or 算出不可 when the denominator is zero.
  def format_rate(value)
    value ? "#{value.round}%" : "算出不可"
  end

  def date_with_wday(date)
    "#{date.year}年#{date.month}月#{date.day}日（#{%w[ 日 月 火 水 木 金 土 ][date.wday]}）"
  end
end
