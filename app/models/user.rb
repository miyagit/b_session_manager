class User < ApplicationRecord
  enum :role, { staff: 0, admin: 1 }, validate: true

  validates :name, presence: true
  validates :line_uid, presence: true, uniqueness: true
end
