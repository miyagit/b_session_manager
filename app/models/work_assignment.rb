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
end
