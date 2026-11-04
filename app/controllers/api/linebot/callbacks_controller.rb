class Api::Linebot::CallbacksController < ActionController::API
  def create
    events = parser.parse(body: request.raw_post, signature: request.headers["X-Line-Signature"].to_s)

    events.each do |event|
      Rails.logger.info("[LINE] #{event.class.name.demodulize}: #{event.source&.user_id}")
    end

    head :ok
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    head :bad_request
  end

  private

  def parser
    Line::Bot::V2::WebhookParser.new(channel_secret: Rails.application.credentials.dig(:line, :channel_secret))
  end
end
