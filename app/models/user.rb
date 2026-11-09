class User < ApplicationRecord
  has_many :shifts, dependent: :restrict_with_error
  has_many :report_results, dependent: :restrict_with_error
  has_many :submitted_reports, class_name: "Report", foreign_key: :submitted_by_id, dependent: :restrict_with_error, inverse_of: :submitted_by

  enum :role, { staff: 0, admin: 1 }, validate: true

  normalizes :line_uid, with: ->(line_uid) { line_uid.strip.presence }

  validates :name, presence: true
  validates :line_uid, uniqueness: true, allow_nil: true
end
