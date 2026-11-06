class WorkAssignment < ApplicationRecord
  belongs_to :work_session
  belongs_to :user
  has_many :report_results, dependent: :restrict_with_error

  enum :status, { unconfirmed: 0, confirmed: 1 }, validate: true

  validates :target_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :work_session_id }

  def confirm!
    update!(status: :confirmed, confirmed_at: Time.current) unless confirmed?
  end

  # The result to count for this staff member: the final report if there is one, otherwise the latest
  # interim report. Interim counts are cumulative, so earlier slots are never added on top.
  def effective_result
    report_results.max_by { |report_result| [ report_result.report.final? ? 1 : 0, report_result.report.report_slot ] }
  end
end
