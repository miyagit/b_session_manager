class Api::Linebot::CallbacksController < ActionController::API
  def create
    events = parser.parse(body: request.raw_post, signature: request.headers["X-Line-Signature"].to_s)

    events.each do |event|
      Rails.logger.info("[LINE] #{event.class.name.demodulize}: #{event.source&.user_id}")

      case event
      when Line::Bot::V2::Webhook::FollowEvent
        create_user(event.source.user_id)
      when Line::Bot::V2::Webhook::JoinEvent
        announce_group_id(event)
      end
    end

    head :ok
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    head :bad_request
  end

  private

  def parser
    Line::Bot::V2::WebhookParser.new(channel_secret: ENV.fetch("LINE_CHANNEL_SECRET"))
  end

  # Re-following after a block sends another follow event, so only create the user once
  def create_user(line_uid)
    User.find_or_create_by!(line_uid: line_uid) do |user|
      profile = LineBot.client.get_profile(user_id: line_uid)

      if profile.is_a?(Line::Bot::V2::MessagingApi::UserProfileResponse)
        user.name = profile.display_name
        user.avatar_url = profile.picture_url
      else
        user.name = "LINEユーザー"
      end
    end
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
