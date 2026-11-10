# Messaging API access shared by the webhook and the report posting job. Settings come from the environment.
module LineBot
  def self.client
    Line::Bot::V2::MessagingApi::ApiClient.new(channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN"))
  end

  # The one LINE group every report is posted to (the official account must be a member).
  def self.report_group_id
    ENV["LINE_REPORT_GROUP_ID"].presence
  end
end
