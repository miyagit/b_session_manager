# One booth on one day: the location, the day's budget and the staff shifts. Reports hang off it.
class WorkSession < ApplicationRecord
  belongs_to :work_location
  # Declared before shifts so the "has reports" check runs before shifts are destroyed.
  has_many :reports, dependent: :restrict_with_error
  has_many :shifts, dependent: :destroy
  has_many :users, through: :shifts

  accepts_nested_attributes_for :shifts, allow_destroy: true, reject_if: ->(attributes) { attributes[:user_id].blank? }

  validates :work_date, presence: true, uniqueness: { scope: :work_location_id, message: "には、この稼働場所の稼働予定がすでにあります" }
  validates :budget_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :removed_shifts_have_no_results

  # The day's budget starts from the location's base budget and can then be changed per session.
  before_validation :copy_location_budget, on: :create

  def display_name = work_location.name
  def start_report = reports.find(&:start?)
  def final_report = reports.find(&:final?)
  def interim_reports = reports.select(&:interim?).sort_by(&:report_slot)
  def registered_slots = interim_reports.map(&:report_slot)
  def shift_for(user_id) = shifts.find { |shift| shift.user_id == user_id }

  # Nothing left to report: start, every interim slot and the final report are in.
  def all_reports_filed?
    start_report.present? && final_report.present? && (Report::INTERIM_SLOTS - registered_slots).empty?
  end

  # The final report, otherwise the latest interim report, otherwise the start report.
  def latest_report
    reports.max_by { |report| [ report.final? ? 2 : (report.interim? ? 1 : 0), report.report_slot.to_i ] }
  end

  # :confirmed once a final report exists, :provisional with interim reports only, :none before any results.
  def result_status
    if reports.any?(&:final?) then :confirmed
    elsif reports.any?(&:interim?) then :provisional
    else :none
    end
  end

  # Each staff member's effective result: from the final report, otherwise from their latest interim report.
  # Interim counts are cumulative, so earlier slots are never added on top.
  def effective_results
    reports.flat_map(&:report_results).group_by(&:user_id).values.map do |results|
      results.max_by { |result| [ result.report.final? ? 1 : 0, result.report.report_slot.to_i ] }
    end
  end

  def effective_result_for(user_id) = effective_results.find { |result| result.user_id == user_id }
  def acquired_count = effective_results.sum(&:acquired_count)
  def approach_count = effective_results.sum(&:approach_count)
  def card_count = effective_results.sum { |result| result.card_count.to_i }
  def target_acquired_count = shifts.sum(&:target_acquired_count)

  # Percentage, or nil when it can't be calculated (no budget).
  def achievement_rate
    return if budget_count.nil? || budget_count.zero?

    acquired_count * 100.0 / budget_count
  end

  private
    def copy_location_budget
      self.budget_count ||= work_location&.budget_count
    end

    def removed_shifts_have_no_results
      shifts.select(&:marked_for_destruction?).each do |shift|
        next unless reports.any? { |report| report.report_results.any? { |result| result.user_id == shift.user_id } }

        errors.add(:base, "#{shift.user.name}には報告があるため、シフトから外せません")
      end
    end
end
