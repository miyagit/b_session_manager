class Liff::LineDeliveriesController < Liff::BaseController
  before_action :require_staff

  # POST /liff/reports/1/line_delivery
  # The completion page calls this after the staff member has posted the report to the group from LINE itself
  # (share target picker or sendMessages), so the delivery shows as sent in the admin screens.
  def create
    report = current_staff.submitted_reports.find(params.expect(:report_id))
    LineMessageDelivery.find_or_initialize_by(report: report).update!(status: :sent, sent_at: Time.current, error_message: nil)
    head :no_content
  end
end
