class Report < ApplicationRecord
  SLOTS = [ 13, 16, 19, 22 ].freeze
  MAX_RESULTS = 3

  belongs_to :work_session
  belongs_to :submitted_by, class_name: "User"
  has_many :report_results, dependent: :destroy
  has_one :line_message_delivery, dependent: :destroy

  # Rows without a count are skipped so a form can list every assigned staff member and only save the ones reported.
  accepts_nested_attributes_for :report_results, reject_if: ->(attributes) { attributes[:acquired_count].blank? }

  enum :report_type, { interim: "interim", final: "final" }, validate: true

  validates :report_slot, inclusion: { in: SLOTS }, uniqueness: { scope: :work_session_id }
  validates :reported_at, presence: true
  validates :report_results, length: { in: 1..MAX_RESULTS }
  validate :report_results_belong_to_work_session

  # Interim counts are cumulative, so the booth total is the sum of this report only (never of earlier slots).
  def booth_acquired_count
    report_results.sum(&:acquired_count)
  end

  # Percentage, or nil when it can't be calculated (no budget).
  def achievement_rate
    budget = work_session.budget_count
    return if budget.nil? || budget.zero?

    booth_acquired_count * 100.0 / budget
  end

  # One result per assignment, in the given order, for forms that list every assigned staff member.
  # Results already entered for an assignment are kept so a failed submit shows the typed values.
  def result_rows_for(work_assignments)
    entered = report_results.index_by(&:work_assignment_id)
    work_assignments.map do |work_assignment|
      report_result = entered[work_assignment.id] || report_results.build
      report_result.work_assignment = work_assignment
      report_result
    end
  end

  private
    def report_results_belong_to_work_session
      return if report_results.all? { |report_result| report_result.work_assignment&.work_session_id == work_session_id }

      errors.add(:report_results, "に、この稼働予定に割り当てられていないスタッフが含まれています")
    end
end
