class Report < ApplicationRecord
  SLOTS = [ 13, 16, 19, 22 ].freeze
  MAX_RESULTS = 3

  belongs_to :work_location
  belongs_to :submitted_by, class_name: "User"
  has_many :report_results, dependent: :destroy
  has_one :line_message_delivery, dependent: :destroy

  # Rows without a count are skipped so a form can offer blank staff rows and only save the ones filled in.
  accepts_nested_attributes_for :report_results, reject_if: ->(attributes) { attributes[:acquired_count].blank? }

  enum :report_type, { interim: "interim", final: "final" }, validate: true

  validates :work_date, presence: true
  validates :report_slot, inclusion: { in: SLOTS }, uniqueness: { scope: [ :work_location_id, :work_date ] }
  validates :reported_at, presence: true
  validates :report_results, length: { in: 1..MAX_RESULTS }
  validate :report_results_have_distinct_users

  # Interim counts are cumulative, so the booth total is the sum of this report only (never of earlier slots).
  def booth_acquired_count
    report_results.sum(&:acquired_count)
  end

  # Percentage, or nil when it can't be calculated (no budget).
  def achievement_rate
    budget = work_location.budget_count
    return if budget.nil? || budget.zero?

    booth_acquired_count * 100.0 / budget
  end

  # One result per staff member, in the given order, for forms that list staff rows.
  # Results already entered for a staff member are kept so a failed submit shows the typed values.
  def result_rows_for(users)
    entered = report_results.index_by(&:user_id)
    users.map do |user|
      report_result = entered[user.id] || report_results.build
      report_result.user = user
      report_result
    end
  end

  private
    def report_results_have_distinct_users
      user_ids = report_results.map(&:user_id).compact
      errors.add(:report_results, "に同じスタッフが複数回含まれています") if user_ids.uniq.size != user_ids.size
    end
end
