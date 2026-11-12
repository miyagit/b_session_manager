# The hours a staff member actually worked on a shift (overtime, leaving early), entered with the final report.
# Cinema shifts have fixed hours and no record. Averages are computed from these hours when they exist.
class WorkRecord < ApplicationRecord
  # Plain clock times, so keep them out of time-zone conversion.
  self.skip_time_zone_conversion_for_attributes = [ :started_at, :ended_at ]

  belongs_to :shift

  validates :started_at, :ended_at, presence: true
  validates :shift_id, uniqueness: true
  validate :ended_after_started

  def starts_at = started_at&.strftime("%H:%M")
  def ends_at = ended_at&.strftime("%H:%M")

  # "10:00〜17:30"
  def hours_label = "#{starts_at}〜#{ends_at}"

  private
    def ended_after_started
      return if started_at.nil? || ended_at.nil? || ended_at > started_at

      errors.add(:ended_at, "は開始時刻より後にしてください")
    end
end
