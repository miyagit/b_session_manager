# Messaging API webhook. Staff are linked to LINE from the LIFF (Liff::LinksController), so follow events are only
# logged; the join event is used to tell a group its ID for the optional official-account posting.
class Api::Linebot::CallbacksController < ActionController::API
  def create
    events = parser.parse(body: request.raw_post, signature: request.headers["X-Line-Signature"].to_s)

    events.each do |event|
      Rails.logger.info("[LINE] #{event.class.name.demodulize}: #{event.source&.user_id}")

      announce_group_id(event) if event.is_a?(Line::Bot::V2::Webhook::JoinEvent)
    end

    head :ok
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    head :bad_request
  end

  private

  def parser
    Line::Bot::V2::WebhookParser.new(channel_secret: ENV.fetch("LINE_CHANNEL_SECRET"))
  end

  # When the official account is invited to a group, tell the group its ID so it can be set as the report group.
  def announce_group_id(event)
    group_id = event.source.try(:group_id)
    return if group_id.blank? || event.reply_token.blank?

    text = "このグループのIDは #{group_id} です。\n実績報告の投稿先にするには、.env の LINE_REPORT_GROUP_ID にこの値を設定してサーバーを再起動してください。"
    LineBot.client.reply_message(reply_message_request: Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: event.reply_token, messages: [ Line::Bot::V2::MessagingApi::TextMessage.new(text: text) ]
    ))
  end
end
