# LIFF (LINE Front-end Framework) settings for the staff report screen (/liff).
# Set line.liff_id and line.login_channel_id in credentials, or LIFF_ID / LINE_LOGIN_CHANNEL_ID in the environment.
# login_channel_id is the channel ID of the LINE Login channel the LIFF app belongs to; ID tokens are verified against it.
Rails.application.config.x.liff.id = Rails.application.credentials.dig(:line, :liff_id).presence || ENV["LIFF_ID"].presence
Rails.application.config.x.liff.login_channel_id =
  Rails.application.credentials.dig(:line, :login_channel_id).presence || ENV["LINE_LOGIN_CHANNEL_ID"].presence
