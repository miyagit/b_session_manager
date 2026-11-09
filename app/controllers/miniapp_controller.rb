# LINE ミニアプリ（LIFF）のおみくじ画面
class MiniappController < ApplicationController
  layout "miniapp"

  # LINE アプリ内ブラウザが古い HTML/JS をキャッシュして使い続けないようにする
  # （キャッシュされると画面と送信処理のバージョンがずれる原因になる）
  before_action :disable_http_cache

  def show
    @liff_id = ENV["LIFF_ID"]
  end

  private

  def disable_http_cache
    response.headers["Cache-Control"] = "no-store"
  end
end
