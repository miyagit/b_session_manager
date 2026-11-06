# Aggregates session results for the analytics screen. Each session counts its effective results
# (final report, otherwise the latest interim), so cumulative interim counts are never added up.
class ResultSummary
  AXES = { "day" => "日別", "month" => "月別", "staff" => "スタッフ別", "location" => "稼働場所別", "team" => "チーム別" }.freeze

  Row = Struct.new(:label, :sort_key, :acquired, :target, :approach, :card, :provisional, keyword_init: true) do
    # Percentages, or nil when they can't be calculated.
    def achievement_rate = target.positive? ? acquired * 100.0 / target : nil
    def card_rate = acquired.positive? ? card * 100.0 / acquired : nil
  end

  def self.build(work_sessions, axis:)
    rows = {}
    work_sessions.reject { |work_session| work_session.result_status == :none }.each do |work_session|
      if axis == "staff"
        work_session.work_assignments.each do |work_assignment|
          report_result = work_assignment.effective_result
          add(rows, [ work_assignment.user_id ], label: work_assignment.user.name, sort_key: work_assignment.user.name,
              acquired: report_result&.acquired_count.to_i, target: work_assignment.target_count,
              approach: report_result&.approach_count.to_i, card: report_result&.card_count.to_i, provisional: work_session.result_status == :provisional)
        end
      else
        key, label, sort_key = work_session_key(work_session, axis)
        report_results = work_session.work_assignments.filter_map(&:effective_result)
        add(rows, key, label: label, sort_key: sort_key, acquired: work_session.acquired_count, target: work_session.budget_count.to_i,
            approach: report_results.sum { |report_result| report_result.approach_count.to_i }, card: report_results.sum { |report_result| report_result.card_count.to_i },
            provisional: work_session.result_status == :provisional)
      end
    end
    rows = rows.values.sort_by(&:sort_key)
    %w[ day month ].include?(axis) ? rows : rows.sort_by { |row| -row.acquired }
  end

  def self.work_session_key(work_session, axis)
    date = work_session.work_date
    case axis
    when "day" then [ [ date ], "#{date.month}/#{date.day}（#{%w[ 日 月 火 水 木 金 土 ][date.wday]}）", date ]
    when "month" then [ [ date.beginning_of_month ], "#{date.year}年#{date.month}月", date.beginning_of_month ]
    when "location" then [ [ work_session.work_location_id ], work_session.work_location.name, work_session.work_location_id ]
    when "team" then [ [ work_session.team_name.to_s ], work_session.team_name.presence || "（チーム名なし）", work_session.team_name.to_s ]
    end
  end

  def self.add(rows, key, label:, sort_key:, acquired:, target:, approach:, card:, provisional:)
    row = rows[key] ||= Row.new(label: label, sort_key: sort_key, acquired: 0, target: 0, approach: 0, card: 0, provisional: false)
    row.acquired += acquired
    row.target += target
    row.approach += approach
    row.card += card
    row.provisional ||= provisional
  end
  private_class_method :work_session_key, :add
end
