class Api::Linebot::CallbacksController < ActionController::API
  def create
    events = parser.parse(body: request.raw_post, signature: request.headers["X-Line-Signature"].to_s)

    events.each do |event|
      Rails.logger.info("[LINE] #{event.class.name.demodulize}: #{event.source&.user_id}")

      case event
      when Line::Bot::V2::Webhook::FollowEvent
        create_user(event.source.user_id)
      end
    end

    head :ok
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    head :bad_request
  end

  private

  def parser
    Line::Bot::V2::WebhookParser.new(channel_secret: Rails.application.credentials.dig(:line, :channel_secret))
  end

  def client
    Line::Bot::V2::MessagingApi::ApiClient.new(channel_access_token: Rails.application.credentials.dig(:line, :channel_access_token))
  end

  # Re-following after a block sends another follow event, so only create the user once
  def create_user(line_uid)
    User.find_or_create_by!(line_uid: line_uid) do |user|
      profile = client.get_profile(user_id: line_uid)

      if profile.is_a?(Line::Bot::V2::MessagingApi::UserProfileResponse)
        user.name = profile.display_name
        user.avatar_url = profile.picture_url
      else
        user.name = "LINEユーザー"
      end
    end
  end
end
