class ReportResult < ApplicationRecord
  belongs_to :report
  belongs_to :user

  validates :acquired_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :approach_count, :card_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :user_id, uniqueness: { scope: :report_id }

  # Percentage, or nil when it can't be calculated (nothing acquired or no card count).
  def card_rate
    return if card_count.nil? || acquired_count.zero?

    card_count * 100.0 / acquired_count
  end
end
