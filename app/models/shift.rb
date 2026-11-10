# A staff member's assignment to a booth for the day. The personal targets (and, for a full-day shift, the start
# time) are declared in the start report, so they stay empty until then.
class Shift < ApplicationRecord
  # Working hours by shift type: "HH:MM" start and end. A full-day start is declared in the start report; ends are fixed.
  FIXED_HOURS = { "first_half" => [ "10:00", "16:00" ], "second_half" => [ "16:00", "22:00" ], "full_day" => [ nil, "22:00" ] }.freeze

  # A plain clock time, so keep it out of time-zone conversion.
  self.skip_time_zone_conversion_for_attributes = [ :started_at ]

  belongs_to :work_session
  belongs_to :user

  enum :shift_type, { first_half: "first_half", second_half: "second_half", full_day: "full_day" }, validate: true

  validates :target_acquired_count, :target_approach_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :target_acquired_count, :target_approach_count, presence: true, on: :start_report
  validates :started_at, presence: true, on: :start_report, if: :full_day?
  validates :user_id, uniqueness: { scope: :work_session_id }

  def targets_set? = target_acquired_count.present? && target_approach_count.present?

  # "10:00" style start, or nil for a full-day shift before the start report.
  def starts_at
    full_day? ? started_at&.strftime("%H:%M") : FIXED_HOURS.fetch(shift_type)[0]
  end

  def ends_at = FIXED_HOURS.fetch(shift_type)[1]

  # "10:00〜16:00"
  def hours_label = "#{starts_at || "開始未定"}〜#{ends_at}"
end
