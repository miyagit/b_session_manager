# One team's month against its budgets, laid out like the team sheet: 目標 (the budgets and the registered donki
# shifts), 現在 (what the reports say), 進捗 (what is left) and 目標ペース比較 (the budget prorated to the hours
# worked so far). Donki booths only, events included; the members' cinema shifts are left out.
#   稼働数:   全日 1.0、前半・後半 0.5
#   稼働時間: hours actually worked for reported shifts (work record, otherwise the shift's hours); planned hours for the rest
#   獲得平均 = 獲得件数 ÷ 稼働時間 × 6   生産性 = 獲得件数 ÷ 稼働時間
#   本日時点の目標 = 予算件数 × 現在稼働時間 ÷ 予定稼働時間
class TeamProgress
  UNIT_HOURS = ResultSummary::DONKI_UNIT_HOURS

  # One member (or the team total). budget is nil until the month's 予算件数 is entered.
  Row = Struct.new(:label, :user_id, :budget, :full_days, :first_halves, :second_halves, :planned_units, :planned_hours,
                   :acquired, :cards, :done_units, :done_hours, :provisional, keyword_init: true) do
    def remaining_acquired = [ budget.to_i - acquired, 0 ].max
    def remaining_units = planned_units - done_units
    def remaining_hours = planned_hours - done_hours

    def target_average = per_unit(budget.to_i, planned_hours)
    def target_productivity = per_hour(budget.to_i, planned_hours)
    def current_average = per_unit(acquired, done_hours)
    def current_productivity = per_hour(acquired, done_hours)
    def required_average = per_unit(remaining_acquired, remaining_hours)
    def required_productivity = per_hour(remaining_acquired, remaining_hours)
    def card_rate = acquired.positive? ? cards * 100.0 / acquired : nil
    def achievement_rate = budget.to_i.positive? ? acquired * 100.0 / budget : nil
    def started? = done_hours.positive?

    # The budget prorated to the hours worked so far; nil until shifts are registered.
    def pace_target = planned_hours.positive? ? budget.to_i * done_hours / planned_hours : nil
    def pace_gap = pace_target && acquired - pace_target
    def pace_rate = pace_target&.positive? ? acquired * 100.0 / pace_target : nil

    # 「▼遅れ」 when behind the pace; nothing before the first shift or when on pace.
    def behind? = pace_gap.present? && pace_gap.negative?

    private
      def per_hour(count, hours) = hours.positive? ? count / hours : nil
      def per_unit(count, hours) = hours.positive? ? count * UNIT_HOURS / hours : nil
  end

  # last_planned_on: the date of the members' last registered donki shift in the month (nil without any).
  attr_reader :team, :month, :rows, :last_planned_on

  def self.build(team, month)
    memberships = team.team_memberships.includes(:user, :team_targets).to_a
    work_sessions = WorkSession.where(work_date: month.all_month, work_location: WorkLocation.donki)
                               .where(id: Shift.where(user_id: memberships.map(&:user_id)).select(:work_session_id))
                               .includes(:work_location, shifts: [ :user, :work_record ], reports: :report_results)
    new(team, month, memberships.map { |membership| row_for(membership, month, work_sessions) }, work_sessions.map(&:work_date).max)
  end

  def initialize(team, month, rows, last_planned_on = nil)
    @team = team
    @month = month
    @rows = rows
    @last_planned_on = last_planned_on
  end

  # The current month with no shift registered after today: the rest of the plan is probably not entered yet,
  # which shrinks 予定稼働時間 to the hours already worked and pushes 本日時点の目標 up to the whole budget.
  def plan_may_be_incomplete?
    today = Date.current
    month == today.beginning_of_month && today < month.end_of_month && (last_planned_on.nil? || last_planned_on <= today)
  end

  # The team's numbers: sums of the members, with the averages computed from the sums.
  def total
    @total ||= Row.new(label: team.name, user_id: nil, budget: rows.sum { |row| row.budget.to_i },
                       full_days: rows.sum(&:full_days), first_halves: rows.sum(&:first_halves), second_halves: rows.sum(&:second_halves),
                       planned_units: rows.sum(&:planned_units), planned_hours: rows.sum(&:planned_hours),
                       acquired: rows.sum(&:acquired), cards: rows.sum(&:cards),
                       done_units: rows.sum(&:done_units), done_hours: rows.sum(&:done_hours), provisional: rows.any?(&:provisional))
  end

  def self.row_for(membership, month, work_sessions)
    row = Row.new(label: membership.user.name, user_id: membership.user_id, budget: membership.budget_for(month),
                  full_days: 0, first_halves: 0, second_halves: 0, planned_units: 0.0, planned_hours: 0.0,
                  acquired: 0, cards: 0, done_units: 0.0, done_hours: 0.0, provisional: false)
    work_sessions.each do |work_session|
      shift = work_session.shift_for(membership.user_id) or next

      row.full_days += 1 if shift.full_day?
      row.first_halves += 1 if shift.first_half?
      row.second_halves += 1 if shift.second_half?
      row.planned_units += shift.work_units
      result = work_session.effective_result_for(shift.user_id)
      if result
        hours = result.worked_hours.to_f
        row.acquired += result.acquired_count
        row.cards += result.card_count.to_i
        row.done_units += shift.work_units
        row.done_hours += hours
        row.planned_hours += hours
        row.provisional ||= work_session.result_status == :provisional
      else
        row.planned_hours += shift.planned_hours
      end
    end
    row
  end
  private_class_method :row_for
end
