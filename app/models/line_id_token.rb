require "net/http"

# Verifies a LIFF ID token with LINE and returns its claims ("sub" is the LINE user ID, plus "name", "picture", ...).
# https://developers.line.biz/ja/reference/line-login/#verify-id-token
class LineIdToken
  VERIFY_URL = URI("https://api.line.me/oauth2/v2.1/verify")
  TIMEOUT_SECONDS = 5

  Error = Class.new(StandardError)

  def self.verify(id_token, channel_id: Rails.configuration.x.liff.login_channel_id)
    raise Error, "LINEログインのチャネルIDが設定されていません" if channel_id.blank?
    raise Error, "IDトークンがありません" if id_token.blank?

    request = Net::HTTP::Post.new(VERIFY_URL)
    request.set_form_data("id_token" => id_token, "client_id" => channel_id)
    response = Net::HTTP.start(VERIFY_URL.host, VERIFY_URL.port, use_ssl: true, open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
      http.request(request)
    end
    claims = JSON.parse(response.body)
    raise Error, claims["error_description"] || claims["error"] || "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    claims
  rescue JSON::ParserError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError, SystemCallError => e
    raise Error, e.message
  end
end
