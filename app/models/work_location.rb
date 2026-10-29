class WorkLocation < ApplicationRecord
  enum :category, { donki: "donki", cinema: "cinema" }, validate: true

  validates :name, presence: true, uniqueness: true
  # nil means the booth budget hasn't been decided yet.
  validates :budget_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
