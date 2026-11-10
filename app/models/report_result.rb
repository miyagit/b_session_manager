class ReportResult < ApplicationRecord
  # A plain clock time, so keep it out of time-zone conversion.
  self.skip_time_zone_conversion_for_attributes = [ :ended_at ]

  belongs_to :report
  belongs_to :user

  validates :acquired_count, :approach_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # The final report also records cards; the end time is optional and overrides the shift's fixed end.
  validates :card_count, presence: true, if: :final_report?
  validates :card_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :user_id, uniqueness: { scope: :report_id }
  validate :ended_after_started

  # The staff member's shift on this booth day, which carries their targets and hours (nil if taken off the booth).
  def shift
    report.work_session.shift_for(user_id)
  end

  # "HH:MM" the staff member finished: the reported end time, otherwise the shift's fixed end.
  def worked_until
    ended_at ? ended_at.strftime("%H:%M") : shift&.ends_at
  end

  # "10:00〜21:30", or nil when the staff member has no shift any more.
  def hours_label
    shift && "#{shift.starts_at || "開始未定"}〜#{worked_until}"
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

    def ended_after_started
      starts_at = shift&.starts_at
      return if ended_at.nil? || starts_at.nil? || ended_at.strftime("%H:%M") > starts_at

      errors.add(:ended_at, "は開始時刻（#{starts_at}）より後にしてください")
    end
end
