# Posts a report to the LINE report group and records the outcome on its LineMessageDelivery.
# Failures are recorded rather than retried blindly; the admin can re-send from the report page.
class LineReportDeliveryJob < ApplicationJob
  queue_as :default

  def perform(report)
    delivery = LineMessageDelivery.find_or_initialize_by(report: report)
    group_id = LineBot.report_group_id
    return delivery.update!(status: :failed, error_message: "LINE_REPORT_GROUP_ID が設定されていません") if group_id.nil?

    delivery.update!(status: :pending, error_message: nil)
    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: group_id, messages: [ Line::Bot::V2::MessagingApi::TextMessage.new(text: LineReportMessage.build(report)) ]
    )
    response, status, = LineBot.client.push_message_with_http_info(push_message_request: request)

    if status == 200
      delivery.update!(status: :sent, sent_at: Time.current, message_id: response.sent_messages&.first&.id, error_message: nil)
    else
      delivery.update!(status: :failed, error_message: "HTTP #{status}: #{response.try(:message) || response.inspect}")
    end
  rescue StandardError => e
    delivery&.update(status: :failed, error_message: e.message)
    raise unless delivery&.persisted?
  end
end
