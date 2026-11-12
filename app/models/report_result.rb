class ReportResult < ApplicationRecord
  belongs_to :report
  belongs_to :user

  validates :acquired_count, :approach_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # The final report also records cards.
  validates :card_count, presence: true, if: :final_report?
  validates :card_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :user_id, uniqueness: { scope: :report_id }

  # The staff member's shift on this booth day, which carries their targets and hours (nil if taken off the booth).
  def shift
    report.work_session.shift_for(user_id)
  end

  # "10:00〜17:30": the hours actually worked when recorded (final report), otherwise the planned hours.
  def hours_label
    shift&.actual_hours_label
  end

  # Hours actually worked, minus the shift's break: from the work record when there is one, otherwise the planned
  # shift hours (interim-only days). Overnight ends wrap past midnight. nil without a shift.
  def worked_hours
    return if shift.nil?

    started = minutes_of_day(shift.actual_starts_at)
    finished = minutes_of_day(shift.actual_ends_at)
    finished += 24 * 60 if finished < started
    [ (finished - started) / 60.0 - shift.break_hours, 0.0 ].max
  end

  # Percentages, or nil when they can't be calculated.
  def card_rate = card_count && rate(card_count, acquired_count)
  def acquired_rate = rate(acquired_count, shift&.target_acquired_count)
  def approach_rate = rate(approach_count, shift&.target_approach_count)

  private
    def final_report?
      report&.final?
    end

    def rate(value, total)
      return if total.nil? || total.zero?

      value * 100.0 / total
    end

    def minutes_of_day(hhmm)
      hours, minutes = hhmm.split(":").map(&:to_i)
      hours * 60 + minutes
    end
end
