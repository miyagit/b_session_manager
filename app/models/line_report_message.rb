# The text posted to the report group for a report, in the agreed LINE format
# (【開始報告】 / 【〇時途中報告】 / 【最終報告】 with a block per staff member). Cinema booths use a slightly shorter
# form: no shift line under the names (the hours are fixed) and, in the final report, 動員数 under the header and
# no booth block unless the booth has a target.
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
        lines = [ staff_header(result.user.name, shift, shift&.hours_label), "■ 進捗状況" ]
        lines << "獲得件数:#{result.acquired_count}件#{target_suffix(shift, shift&.target_acquired_count)}"
        lines << "アプローチ:#{result.approach_count}件#{target_suffix(shift, shift&.target_approach_count)}"
        lines.join("\n")
      end
      [ "【#{@report.report_slot}時途中報告】\n\n#{header}", *blocks ].join("\n\n")
    end

    def final_text
      blocks = @report.report_results.map do |result|
        shift = result.shift
        lines = [ staff_header(result.user.name, shift, result.hours_label), "■ 個人実績" ]
        lines << "獲得件数:#{result.acquired_count}件#{target_suffix(shift, shift&.target_acquired_count)}"
        lines << "アプローチ:#{result.approach_count}件#{target_suffix(shift, shift&.target_approach_count)}"
        lines << "カード数:#{result.card_count}件:カード率:#{rate(result.card_rate)}"
        if shift # the fixed 他社 row has no targets to measure against
          lines << "■ 個人達成率" << "獲得件数達成率:#{rate(result.acquired_rate)}" << "アプローチ達成率:#{rate(result.approach_rate)}"
        end
        lines.join("\n")
      end
      [ "【最終報告】\n#{final_header}", booth_block, *blocks ].compact.join("\n\n")
    end

    def header(with_budget: true)
      date = @work_session.work_date
      lines = [ "#{date.month}月#{date.day}日(#{WDAYS[date.wday]})", "現場:#{@work_session.work_location.name}" ]
      lines << "ブース予算:#{@work_session.budget_count}件" if with_budget && @work_session.budget_count
      lines.join("\n")
    end

    # Cinema: the day's moviegoers go right under 現場 ("動員数:663").
    def final_header
      lines = [ header(with_budget: false) ]
      lines << "動員数:#{@report.audience_count}" if cinema? && @report.audience_count
      lines.join("\n")
    end

    # Booth budget, acquisitions and achievement. Cinema booths only report it when they have a target.
    def booth_block
      return if cinema? && @work_session.budget_count.nil?

      booth = [ "■ ブース実績" ]
      booth << "ブース予算:#{@work_session.budget_count}件" if @work_session.budget_count
      booth << "ブース獲得:#{@report.booth_acquired_count}件"
      booth << "予算達成率:#{rate(@report.achievement_rate)}" if @work_session.budget_count
      booth.join("\n")
    end

    # "【名前】" plus the shift and hours; cinema hours are fixed, so cinema blocks carry the name only.
    def staff_header(name, shift, hours)
      return "【#{name}】" if shift.nil? || cinema?

      "【#{name}】\n#{Shift.human_attribute_name("shift_type.#{shift.shift_type}")}(#{hours})"
    end

    def cinema? = @work_session.work_location.cinema?
    def shifts = @work_session.shifts.sort_by(&:id)
    def count(value) = value ? "#{value}件" : "未設定"
    # The fixed 他社 row has no shift and therefore no targets.
    def target_suffix(shift, target) = shift ? "/目標#{count(target)}" : ""
    def rate(value) = value ? "#{value.round}%" : "—"
end
