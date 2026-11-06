# LINE Messaging API からの Webhook を受け取るコントローラー
class Api::LinebotController < ApplicationController
  # LINE サーバーからの POST には CSRF トークンが付かないため無効化する
  skip_forgery_protection

  # このテキストが送られてきたときだけおみくじを引く
  OMIKUJI_TRIGGER = "おみくじを引く"

  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"].to_s

    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      head :bad_request
      return
    end

    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::MessageEvent
        handle_message_event(event)
      end
    end

    head :ok
  end

  private

  # 「おみくじを引く」というテキストが届いたときだけ結果を返信する（それ以外は無視）
  def handle_message_event(event)
    message = event.message
    return unless message.is_a?(Line::Bot::V2::Webhook::TextMessageContent)
    return unless message.text.strip == OMIKUJI_TRIGGER

    reply_text(event.reply_token, Omikuji.fortune_text)
  end

  def reply_text(reply_token, text)
    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
    reply_request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: [ message ]
    )

    _body, status, _headers = client.reply_message_with_http_info(reply_message_request: reply_request)
    Rails.logger.warn("LINE reply failed (status=#{status})") unless status == 200
  end

  def client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )
  end

  def parser
    @parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: ENV.fetch("LINE_CHANNEL_SECRET")
    )
  end
end
