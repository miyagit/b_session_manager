# The text posted to the report group for a report, in the agreed LINE format
# (【開始報告】 / 【〇時途中報告】 / 【最終報告】 with a block per staff member).
class LineReportMessage
  WDAYS = %w[ 日 月 火 水 木 金 土 ].freeze

  def self.build(report) = new(report).text

  def initialize(report)
    @report = report
    @work_session = report.work_session
  end

  def text
    if @report.start? then start_text
    elsif @report.interim? then interim_text
    else final_text
    end
  end

  private
    def start_text
      blocks = shifts.map do |shift|
        [ staff_header(shift.user.name, shift, shift.hours_label), "■ 目標",
          "獲得件数:#{count(shift.target_acquired_count)}", "アプローチ:#{count(shift.target_approach_count)}" ].join("\n")
      end
      [ "【開始報告】\n#{header}", *blocks ].join("\n\n")
    end

    def interim_text
      blocks = @report.report_results.map do |result|
        shift = result.shift
        [ staff_header(result.user.name, shift, shift&.hours_label), "■ 進捗状況",
          "獲得件数:#{result.acquired_count}件/目標#{count(shift&.target_acquired_count)}",
          "アプローチ:#{result.approach_count}件/目標#{count(shift&.target_approach_count)}" ].join("\n")
      end
      [ "【#{@report.report_slot}時途中報告】\n\n#{header}", *blocks ].join("\n\n")
    end

    def final_text
      booth = [ "■ ブース実績" ]
      booth << "ブース予算:#{@work_session.budget_count}件" if @work_session.budget_count
      booth << "ブース獲得:#{@report.booth_acquired_count}件"
      booth << "予算達成率:#{rate(@report.achievement_rate)}" if @work_session.budget_count
      booth = booth.join("\n")
      blocks = @report.report_results.map do |result|
        shift = result.shift
        [ staff_header(result.user.name, shift, result.hours_label), "■ 個人実績",
          "獲得件数:#{result.acquired_count}件/目標#{count(shift&.target_acquired_count)}",
          "アプローチ:#{result.approach_count}件/目標#{count(shift&.target_approach_count)}",
          "カード数:#{result.card_count}件:カード率:#{rate(result.card_rate)}",
          "■ 個人達成率", "獲得件数達成率:#{rate(result.acquired_rate)}", "アプローチ達成率:#{rate(result.approach_rate)}" ].join("\n")
      end
      [ "【最終報告】\n#{header(with_budget: false)}", booth, *blocks ].join("\n\n")
    end

    def header(with_budget: true)
      date = @work_session.work_date
      lines = [ "#{date.month}月#{date.day}日(#{WDAYS[date.wday]})", "現場:#{@work_session.work_location.name}" ]
      lines << "ブース予算:#{@work_session.budget_count}件" if with_budget && @work_session.budget_count
      lines.join("\n")
    end

    def staff_header(name, shift, hours)
      return "【#{name}】" if shift.nil?

      "【#{name}】\n#{Shift.human_attribute_name("shift_type.#{shift.shift_type}")}(#{hours})"
    end

    def shifts = @work_session.shifts.sort_by(&:id)
    def count(value) = value ? "#{value}件" : "未設定"
    def rate(value) = value ? "#{value.round}%" : "—"
end
