class WorkSession < ApplicationRecord
  belongs_to :work_location
  # Declared before work_assignments so the "has reports" check runs before assignments are destroyed.
  has_many :reports, dependent: :restrict_with_error
  has_many :work_assignments, dependent: :destroy
  has_many :users, through: :work_assignments

  accepts_nested_attributes_for :work_assignments, allow_destroy: true, reject_if: ->(attributes) { attributes[:user_id].blank? }

  validates :work_date, presence: true
  validates :budget_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # The day's budget is a snapshot: it starts from the location's base budget and can then be changed per session.
  before_validation :copy_location_budget, on: :create

  private
    def copy_location_budget
      self.budget_count ||= work_location&.budget_count
    end
end
