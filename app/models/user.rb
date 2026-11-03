class User < ApplicationRecord
  enum :role, { staff: 0, admin: 1 }, validate: true

  normalizes :line_uid, with: ->(line_uid) { line_uid.strip.presence }

  validates :name, presence: true
  validates :line_uid, uniqueness: true, allow_nil: true

  def line_linked?
    line_uid.present?
  end
end
