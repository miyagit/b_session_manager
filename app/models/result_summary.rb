# Aggregates session results for the analytics screen. Each session counts its effective results
# (final report, otherwise the latest interim), so cumulative interim counts are never added up.
class ResultSummary
  AXES = { "day" => "日別", "month" => "月別", "staff" => "スタッフ別", "location" => "稼働場所別", "team" => "チーム別" }.freeze

  Row = Struct.new(:label, :sort_key, :acquired, :target, :approach, :card, :provisional, keyword_init: true) do
    # Percentages, or nil when they can't be calculated.
    def achievement_rate = target.positive? ? acquired * 100.0 / target : nil
    def card_rate = acquired.positive? ? card * 100.0 / acquired : nil
  end

  def self.build(sessions, axis:)
    rows = {}
    sessions.reject { |session| session.result_status == :none }.each do |session|
      if axis == "staff"
        session.work_assignments.each do |assignment|
          result = assignment.effective_result
          add(rows, [ assignment.user_id ], label: assignment.user.name, sort_key: assignment.user.name,
              acquired: result&.acquired_count.to_i, target: assignment.target_count,
              approach: result&.approach_count.to_i, card: result&.card_count.to_i, provisional: session.result_status == :provisional)
        end
      else
        key, label, sort_key = session_key(session, axis)
        results = session.work_assignments.filter_map(&:effective_result)
        add(rows, key, label: label, sort_key: sort_key, acquired: session.acquired_count, target: session.budget_count.to_i,
            approach: results.sum { |result| result.approach_count.to_i }, card: results.sum { |result| result.card_count.to_i },
            provisional: session.result_status == :provisional)
      end
    end
    rows = rows.values.sort_by(&:sort_key)
    %w[ day month ].include?(axis) ? rows : rows.sort_by { |row| -row.acquired }
  end

  def self.session_key(session, axis)
    date = session.work_date
    case axis
    when "day" then [ [ date ], "#{date.month}/#{date.day}（#{%w[ 日 月 火 水 木 金 土 ][date.wday]}）", date ]
    when "month" then [ [ date.beginning_of_month ], "#{date.year}年#{date.month}月", date.beginning_of_month ]
    when "location" then [ [ session.work_location_id ], session.work_location.name, session.work_location_id ]
    when "team" then [ [ session.team_name.to_s ], session.team_name.presence || "（チーム名なし）", session.team_name.to_s ]
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
  private_class_method :session_key, :add
end
