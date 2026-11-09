require "net/http"

# LIFF の liff.getIDToken() で取得した ID トークンを LINE のサーバーで検証する
# https://developers.line.biz/ja/reference/line-login/#verify-id-token
module LineIdToken
  VERIFY_URL = URI("https://api.line.me/oauth2/v2.1/verify")

  module_function

  # 検証に成功したらユーザー ID（sub）を、失敗したら nil を返す
  def verify(id_token)
    return nil if id_token.blank?

    response = Net::HTTP.post_form(VERIFY_URL, id_token: id_token, client_id: ENV.fetch("LIFF_CHANNEL_ID"))
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("LINE ID token verify failed (status=#{response.code} body=#{response.body})")
      return nil
    end

    JSON.parse(response.body)["sub"]
  rescue JSON::ParserError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError => e
    Rails.logger.warn("LINE ID token verify error: #{e.class}: #{e.message}")
    nil
  end
end
