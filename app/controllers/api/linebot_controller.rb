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

    LineMessaging.reply_text(event.reply_token, Omikuji.fortune_text)
  end

  def parser
    @parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: ENV.fetch("LINE_CHANNEL_SECRET")
    )
  end
end
