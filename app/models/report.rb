# A booth's report filed by a staff member from LINE: the start report (declares targets), interim reports at 13,
# 16 and 19 (cumulative counts) and the final report (counts, cards and hours worked; cinema booths also the day's
# moviegoers in audience_count). Reports are per person: each covers the staff whose rows were filled in (usually the
# reporter alone), so a booth day may have several reports of the same type. created_at is the time of the report.
class Report < ApplicationRecord
  INTERIM_SLOTS = [ 13, 16, 19 ].freeze

  belongs_to :work_session
  belongs_to :submitted_by, class_name: "User"
  has_many :report_results, dependent: :destroy, inverse_of: :report
  has_one :line_message_delivery, dependent: :destroy

  # Rows without a count are skipped so the form can list every staff member and only save the ones filled in.
  accepts_nested_attributes_for :report_results, reject_if: ->(attributes) { attributes[:acquired_count].blank? }

  enum :report_type, { start: "start", interim: "interim", final: "final" }, validate: true

  before_validation :clear_slot_unless_interim, :clear_audience_unless_cinema_final

  validates :report_slot, inclusion: { in: INTERIM_SLOTS, message: "を選んでください" }, if: :interim?
  validates :report_results, length: { minimum: 1 }, unless: :start?
  # Optional: some theaters don't disclose their attendance.
  validates :audience_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :start_report_covers_someone, if: :start?
  validate :report_results_belong_to_work_session

  # The staff this report is about: the ones whose targets a start report set, otherwise the ones with results.
  def covers?(user_id)
    submitted_by_id == user_id || (start? ? covered_user_ids.include?(user_id) : report_results.any? { |result| result.user_id == user_id })
  end

  # The shifts a start report declared targets for (every shift for reports filed before this was recorded).
  def covered_shifts
    shifts = work_session.shifts.sort_by(&:id)
    covered_user_ids.empty? ? shifts : shifts.select { |shift| covered_user_ids.include?(shift.user_id) }
  end

  # The booth's numbers as of this report: each staff member's latest result from the reports filed up to it, so a
  # report covering one person still shows the whole booth.
  def booth_results = work_session.effective_results(as_of: self)
  def booth_acquired_count = booth_results.sum(&:acquired_count)

  # Percentage, or nil when it can't be calculated (no budget).
  def achievement_rate
    budget = work_session.budget_count
    return if budget.nil? || budget.zero?

    booth_acquired_count * 100.0 / budget
  end

  # One result per staff member, in the given order, for forms. Results already entered are kept so a failed
  # submit shows the typed values.
  def result_rows_for(users)
    entered = report_results.index_by(&:user_id)
    users.map do |user|
      report_result = entered[user.id] || report_results.build
      report_result.user = user
      report_result
    end
  end

  private
    def clear_slot_unless_interim
      self.report_slot = nil unless interim?
    end

    # 動員数 belongs to the final report of a cinema booth only.
    def clear_audience_unless_cinema_final
      self.audience_count = nil unless final? && work_session&.work_location&.cinema?
    end

    def start_report_covers_someone
      errors.add(:base, "目標を入力したスタッフがいません") if covered_user_ids.empty?
    end

    # Every result belongs to a staff member on the booth; cinema booths may also carry the fixed 他社 row.
    def report_results_belong_to_work_session
      return if work_session.nil?
      return if report_results.all? { |report_result| work_session.shift_for(report_result.user_id) || other_company_allowed?(report_result) }

      errors.add(:report_results, "に、この稼働予定にシフトがないスタッフが含まれています")
    end

    def other_company_allowed?(report_result)
      work_session.work_location.cinema? && report_result.user&.other_company?
    end
end
