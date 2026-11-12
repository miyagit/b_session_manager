# A staff member's assignment to a booth for the day. The personal targets (and, for a full-day shift, the flex start
# time) are declared in the start report; the hours actually worked are recorded with the final report (WorkRecord).
class Shift < ApplicationRecord
  # Planned working hours by shift type ("HH:MM" start and end). Donki booths run 前半 / 後半 / 全日, cinema booths
  # the single シネマ shift. 全日 is a FULL_DAY_WORK_HOURS-hour flex shift starting at or after the window start: the
  # start is declared in the start report and the end follows from it (it may run past the nominal window end).
  FIXED_HOURS = {
    "first_half" => [ "10:00", "16:00" ],
    "second_half" => [ "16:00", "22:00" ],
    "full_day" => [ "10:00", "22:00" ],
    "cinema" => [ "10:00", "19:00" ]
  }.freeze
  FULL_DAY_WORK_HOURS = 9
  # Unpaid break inside the shift, excluded from the hours worked (cinema: 9 hours on site = 8 hours worked).
  BREAK_HOURS = { "cinema" => 1.0 }.freeze
  TYPES_BY_CATEGORY = { "donki" => %w[ first_half second_half full_day ], "cinema" => %w[ cinema ] }.freeze

  # A plain clock time, so keep it out of time-zone conversion.
  self.skip_time_zone_conversion_for_attributes = [ :started_at ]

  belongs_to :work_session
  belongs_to :user
  has_one :work_record, dependent: :destroy

  enum :shift_type, { first_half: "first_half", second_half: "second_half", full_day: "full_day", cinema: "cinema" }, validate: true

  validates :target_acquired_count, :target_approach_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :target_acquired_count, :target_approach_count, presence: true, on: :start_report
  validates :started_at, presence: true, on: :start_report, if: :full_day?
  validates :user_id, uniqueness: { scope: :work_session_id }
  validate :shift_type_allowed_for_location
  validate :started_at_not_before_window, if: -> { full_day? && started_at.present? }

  # Shift types a booth category offers, in display order.
  def self.types_for(category) = TYPES_BY_CATEGORY.fetch(category, [])

  # "HH:MM" as a Time (on 2000-01-01), for time fields and arithmetic.
  def self.clock(hhmm) = Time.utc(2000, 1, 1, *hhmm.split(":").map(&:to_i))

  def targets_set? = target_acquired_count.present? && target_approach_count.present?
  def break_hours = BREAK_HOURS.fetch(shift_type, 0.0)

  # Cinema hours are fixed, so no actual hours are recorded for them.
  def records_hours? = !cinema?

  # Planned "10:00" style start: the declared flex start for 全日 (window start until declared), fixed otherwise.
  def starts_at
    return FIXED_HOURS.fetch(shift_type)[0] unless full_day?

    started_at ? started_at.strftime("%H:%M") : FIXED_HOURS["full_day"][0]
  end

  # Planned "16:00" style end: start + FULL_DAY_WORK_HOURS for a declared 全日 (window end until declared), fixed otherwise.
  def ends_at
    return FIXED_HOURS.fetch(shift_type)[1] unless full_day?

    started_at ? (started_at + FULL_DAY_WORK_HOURS.hours).strftime("%H:%M") : FIXED_HOURS["full_day"][1]
  end

  # Planned hours, "10:00〜16:00".
  def hours_label = "#{starts_at}〜#{ends_at}"

  # Hours actually worked when recorded, otherwise the planned hours.
  def actual_hours_label = work_record&.hours_label || hours_label
  def actual_starts_at = work_record&.starts_at || starts_at
  def actual_ends_at = work_record&.ends_at || ends_at

  private
    def shift_type_allowed_for_location
      category = work_session&.work_location&.category
      return if category.nil? || shift_type.blank? || self.class.types_for(category).include?(shift_type)

      allowed = self.class.types_for(category).map { |type| Shift.human_attribute_name("shift_type.#{type}") }.join("・")
      errors.add(:shift_type, "は#{WorkLocation.human_attribute_name("category.#{category}")}では「#{allowed}」から選んでください")
    end

    def started_at_not_before_window
      earliest = FIXED_HOURS["full_day"][0]
      return if started_at.strftime("%H:%M") >= earliest

      errors.add(:started_at, "は#{earliest}以降で入力してください")
    end
end
