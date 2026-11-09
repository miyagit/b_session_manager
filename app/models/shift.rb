# A staff member's assignment to a booth for the day, with the personal targets the reports are measured against.
class Shift < ApplicationRecord
  belongs_to :work_session
  belongs_to :user

  enum :shift_type, { first_half: "first_half", second_half: "second_half", full_day: "full_day" }, validate: true

  validates :target_acquired_count, :target_approach_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :work_session_id }
end
