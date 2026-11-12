# Aggregates work-session results for the analytics screen. Each session counts its effective results
# (final report, otherwise the latest interim), so cumulative interim counts are never added up.
class ResultSummary
  AXES = { "day" => "日別", "month" => "月別", "staff" => "スタッフ別", "location" => "稼働場所別" }.freeze

  # Averages are normalized per booth category: donki per 6 hours worked, cinema per 8-hour day.
  DONKI_UNIT_HOURS = 6
  CINEMA_UNIT_HOURS = 8

  # target is the booth budget for booth rows and the sum of personal targets for staff rows.
  # user_id and the per-category acquisitions/hours actually worked are filled for staff rows only.
  Row = Struct.new(:label, :sort_key, :user_id, :acquired, :target, :approach, :card, :provisional,
                   :donki_acquired, :donki_hours, :cinema_acquired, :cinema_hours, keyword_init: true) do
    # Percentages, or nil when they can't be calculated.
    def achievement_rate = target.positive? ? acquired * 100.0 / target : nil
    def card_rate = acquired.positive? ? card * 100.0 / acquired : nil

    # Acquisitions per DONKI_UNIT_HOURS worked at donki booths, or nil without any donki hours.
    def donki_average = donki_hours.positive? ? donki_acquired * DONKI_UNIT_HOURS.to_f / donki_hours : nil

    # Acquisitions per CINEMA_UNIT_HOURS worked at cinema booths (one day), or nil without any cinema hours.
    def cinema_average = cinema_hours.positive? ? cinema_acquired * CINEMA_UNIT_HOURS.to_f / cinema_hours : nil
  end

  # work_sessions must have work_location, shifts (with user) and reports (with report_results) preloaded.
  def self.build(work_sessions, axis:)
    rows = {}
    work_sessions.reject { |work_session| work_session.result_status == :none }.each do |work_session|
      provisional = work_session.result_status == :provisional
      if axis == "staff"
        work_session.shifts.each do |shift|
          result = work_session.effective_result_for(shift.user_id)
          category_hours = { "#{shift.cinema? ? "cinema" : "donki"}_acquired": result&.acquired_count.to_i,
                             "#{shift.cinema? ? "cinema" : "donki"}_hours": result&.worked_hours.to_f }
          add(rows, [ shift.user_id ], label: shift.user.name, sort_key: shift.user.name, user_id: shift.user_id, acquired: result&.acquired_count.to_i,
              target: shift.target_acquired_count.to_i, approach: result&.approach_count.to_i, card: result&.card_count.to_i,
              provisional: provisional, **category_hours)
        end
      else
        key, label, sort_key = work_session_key(work_session, axis)
        add(rows, key, label: label, sort_key: sort_key, acquired: work_session.acquired_count, target: work_session.budget_count.to_i,
            approach: work_session.approach_count, card: work_session.card_count, provisional: provisional)
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
    end
  end

  def self.add(rows, key, label:, sort_key:, acquired:, target:, approach:, card:, provisional:, user_id: nil,
               donki_acquired: 0, donki_hours: 0.0, cinema_acquired: 0, cinema_hours: 0.0)
    row = rows[key] ||= Row.new(label: label, sort_key: sort_key, user_id: user_id, acquired: 0, target: 0, approach: 0, card: 0, provisional: false,
                                donki_acquired: 0, donki_hours: 0.0, cinema_acquired: 0, cinema_hours: 0.0)
    row.acquired += acquired
    row.target += target
    row.approach += approach
    row.card += card
    row.donki_acquired += donki_acquired
    row.donki_hours += donki_hours
    row.cinema_acquired += cinema_acquired
    row.cinema_hours += cinema_hours
    row.provisional ||= provisional
  end
  private_class_method :work_session_key, :add
end
