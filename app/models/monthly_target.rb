# Targets shared by every team in a month: for now the card rate (目標カード率).
class MonthlyTarget < ApplicationRecord
  DEFAULT_CARD_RATE = 60

  validates :month, presence: true, uniqueness: true
  validates :card_rate, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # The month's record, or an unsaved one carrying the default rate.
  def self.for(month)
    find_or_initialize_by(month: month.beginning_of_month) { |target| target.card_rate = DEFAULT_CARD_RATE }
  end
end
