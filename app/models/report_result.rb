class ReportResult < ApplicationRecord
  # Hours worked are plain clock times, so keep them out of time-zone conversion.
  self.skip_time_zone_conversion_for_attributes = [ :started_at, :ended_at ]

  belongs_to :report
  belongs_to :user

  validates :acquired_count, :approach_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # The final report also records cards and the hours actually worked.
  validates :card_count, :started_at, :ended_at, presence: true, if: :final_report?
  validates :card_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :user_id, uniqueness: { scope: :report_id }
  validate :ended_after_started

  # The staff member's shift on this booth day, which carries their targets (nil if they were taken off the booth).
  def shift
    report.work_session.shift_for(user_id)
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
      return if started_at.nil? || ended_at.nil? || ended_at > started_at

      errors.add(:ended_at, "は開始時刻より後にしてください")
    end
end
