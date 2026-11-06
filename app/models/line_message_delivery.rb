class LineMessageDelivery < ApplicationRecord
  belongs_to :report

  enum :status, { pending: "pending", sent: "sent", failed: "failed" }, validate: true

  validates :report_id, uniqueness: true
end
