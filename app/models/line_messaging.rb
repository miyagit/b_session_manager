# LINE Messaging API でテキストを送るための薄いラッパー
# Bot の返信（reply）とミニアプリからのプッシュ送信（push）で共通に使う
module LineMessaging
  module_function

  # Webhook の reply_token を使って返信する。LINE の HTTP ステータスを返す
  def reply_text(reply_token, text)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: [ text_message(text) ]
    )
    _body, status, _headers = client.reply_message_with_http_info(reply_message_request: request)
    log_failure("reply", status)
    status
  end

  # ユーザー ID 宛てにプッシュ送信する。LINE の HTTP ステータスを返す
  # ※ プッシュ送信は公式アカウントの月間メッセージ数にカウントされる
  def push_text(user_id, text)
    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: user_id,
      messages: [ text_message(text) ]
    )
    _body, status, _headers = client.push_message_with_http_info(push_message_request: request)
    log_failure("push", status)
    status
  end

  def text_message(text)
    Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
  end

  def client
    Line::Bot::V2::MessagingApi::ApiClient.new(channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN"))
  end

  def log_failure(kind, status)
    Rails.logger.warn("LINE #{kind} failed (status=#{status})") unless status == 200
  end
end
