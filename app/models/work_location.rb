class WorkLocation < ApplicationRecord
  has_many :work_sessions, dependent: :restrict_with_error

  enum :category, { donki: "donki", cinema: "cinema" }, validate: true

  normalizes :line_group_id, with: ->(line_group_id) { line_group_id.strip.presence }

  validates :name, presence: true, uniqueness: true
  # nil means the booth budget hasn't been decided yet; each work session copies it as its starting budget.
  validates :budget_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
