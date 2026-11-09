# ミニアプリの画面からおみくじを引く API
class Api::OmikujiController < ApplicationController
  # 引いた結果を署名付きトークンに入れて持ち回るときの用途名
  TOKEN_PURPOSE = "omikuji_result"
  # トークンの有効期限（引いてから送るまでの猶予）
  TOKEN_TTL = 1.hour

  # おみくじを引いて結果を返す
  # 返した結果は token（署名付き）にも入れ、share ではこの token だけを信用する
  def create
    result = Omikuji.draw
    token = verifier.generate(Omikuji.id_of(result), purpose: TOKEN_PURPOSE, expires_in: TOKEN_TTL)

    render json: { name: result.name, message: result.message, text: result.to_text, token: token }
  end

  # create で引いた結果を、公式アカウントからユーザーのトークにプッシュ送信する
  # params: token（create が返した署名付きトークン）, id_token（liff.getIDToken() の値）
  # 送る内容は token から復元するので、画面に表示された結果と必ず一致する
  def share
    result = drawn_result
    return render json: { error: "invalid_token" }, status: :unprocessable_content unless result

    # ID トークンを LINE で検証し、送信先のユーザー ID を取り出す（クライアントから渡された ID は信用しない）
    user_id = LineIdToken.verify(params[:id_token])
    return render json: { error: "invalid_id_token" }, status: :unauthorized unless user_id

    status = LineMessaging.push_text(user_id, result.to_text)
    if status == 200
      head :no_content
    else
      render json: { error: "push_failed", line_status: status }, status: :bad_gateway
    end
  end

  private

  # create が署名したトークンから、引いた結果を復元する
  # 署名が不正・期限切れなら verified が nil を返す（＝クライアントは結果を書き換えられない）
  def drawn_result
    id = verifier.verified(params[:token].to_s, purpose: TOKEN_PURPOSE)
    Omikuji.at(id)
  end

  def verifier
    Rails.application.message_verifier(:omikuji)
  end
end
