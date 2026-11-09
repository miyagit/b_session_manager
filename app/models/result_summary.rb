# Aggregates reports for the analytics screen. Each booth day counts its effective results (see BoothDay),
# so cumulative interim counts are never added up.
class ResultSummary
  AXES = { "day" => "日別", "month" => "月別", "staff" => "スタッフ別", "location" => "稼働場所別" }.freeze

  # target is the booth budget; staff rows have no target since personal goals aren't tracked.
  Row = Struct.new(:label, :sort_key, :acquired, :target, :approach, :card, :provisional, keyword_init: true) do
    # Percentages, or nil when they can't be calculated.
    def achievement_rate = target.positive? ? acquired * 100.0 / target : nil
    def card_rate = acquired.positive? ? card * 100.0 / acquired : nil
  end

  # reports must have work_location and report_results (with user) preloaded.
  def self.build(reports, axis:)
    rows = {}
    BoothDay.build(reports).each do |booth_day|
      provisional = booth_day.result_status == :provisional
      if axis == "staff"
        booth_day.effective_results.each do |report_result|
          add(rows, [ report_result.user_id ], label: report_result.user.name, sort_key: report_result.user.name, acquired: report_result.acquired_count,
              target: 0, approach: report_result.approach_count.to_i, card: report_result.card_count.to_i, provisional: provisional)
        end
      else
        key, label, sort_key = booth_day_key(booth_day, axis)
        add(rows, key, label: label, sort_key: sort_key, acquired: booth_day.acquired_count, target: booth_day.budget_count.to_i,
            approach: booth_day.approach_count, card: booth_day.card_count, provisional: provisional)
      end
    end
    rows = rows.values.sort_by(&:sort_key)
    %w[ day month ].include?(axis) ? rows : rows.sort_by { |row| -row.acquired }
  end

  def self.booth_day_key(booth_day, axis)
    date = booth_day.work_date
    case axis
    when "day" then [ [ date ], "#{date.month}/#{date.day}（#{%w[ 日 月 火 水 木 金 土 ][date.wday]}）", date ]
    when "month" then [ [ date.beginning_of_month ], "#{date.year}年#{date.month}月", date.beginning_of_month ]
    when "location" then [ [ booth_day.work_location.id ], booth_day.work_location.name, booth_day.work_location.id ]
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
  private_class_method :booth_day_key, :add
end
