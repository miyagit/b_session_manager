# A booth's report filed by a staff member from LINE: the start report (confirms the targets), interim reports
# at 13, 16 and 19 (cumulative counts) and the final report (counts, cards and hours worked).
# created_at is the time of the report.
class Report < ApplicationRecord
  INTERIM_SLOTS = [ 13, 16, 19 ].freeze

  belongs_to :work_session
  belongs_to :submitted_by, class_name: "User"
  has_many :report_results, dependent: :destroy, inverse_of: :report
  has_one :line_message_delivery, dependent: :destroy

  # Rows without a count are skipped so the form can list every staff member and only save the ones filled in.
  accepts_nested_attributes_for :report_results, reject_if: ->(attributes) { attributes[:acquired_count].blank? }

  enum :report_type, { start: "start", interim: "interim", final: "final" }, validate: true

  before_validation :clear_slot_unless_interim

  validates :report_slot, inclusion: { in: INTERIM_SLOTS, message: "を選んでください" }, if: :interim?
  validates :report_slot, uniqueness: { scope: :work_session_id }, if: -> { interim? && report_slot.present? }
  validates :report_results, length: { minimum: 1 }, unless: :start?
  validate :single_start_and_final_report
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

    def single_start_and_final_report
      return if interim? || report_type.blank? || work_session.nil?
      return unless work_session.reports.where(report_type: report_type).where.not(id: id).exists?

      errors.add(:base, "#{Report.human_attribute_name("report_type.#{report_type}")}はすでに登録されています")
    end

    def report_results_belong_to_work_session
      return if work_session.nil?
      return if report_results.all? { |report_result| work_session.shift_for(report_result.user_id) }

      errors.add(:report_results, "に、この稼働予定にシフトがないスタッフが含まれています")
    end
end
