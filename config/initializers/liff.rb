# LIFF (LINE Front-end Framework) settings for the staff report screen (/liff), read from the environment
# (.env via dotenv-rails in development and test). login_channel_id is the channel ID of the LINE Login channel
# the LIFF app belongs to; ID tokens are verified against it.
Rails.application.config.x.liff.id = ENV["LIFF_ID"].presence
Rails.application.config.x.liff.login_channel_id = ENV["LINE_LOGIN_CHANNEL_ID"].presence
