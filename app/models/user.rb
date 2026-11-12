class User < ApplicationRecord
  OTHER_COMPANY_NAME = "他社"

  has_many :shifts, dependent: :restrict_with_error
  has_many :report_results, dependent: :restrict_with_error
  has_many :submitted_reports, class_name: "Report", foreign_key: :submitted_by_id, dependent: :restrict_with_error, inverse_of: :submitted_by
  has_many :team_memberships, dependent: :restrict_with_error

  enum :role, { staff: 0, admin: 1 }, validate: true

  # Real staff members: everything except the fixed 他社 row.
  scope :people, -> { where(other_company: false) }

  normalizes :line_uid, with: ->(line_uid) { line_uid.strip.presence }

  validates :name, presence: true
  validates :line_uid, uniqueness: true, allow_nil: true

  # The fixed "他社" row that cinema reports can carry results for (no shift, no LINE account, never ranked).
  def self.other_company
    find_or_create_by!(other_company: true) { |user| user.name = OTHER_COMPANY_NAME }
  end
end
