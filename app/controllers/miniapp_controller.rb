# LINE ミニアプリ（LIFF）のおみくじ画面
class MiniappController < ApplicationController
  layout "miniapp"

  def show
    @liff_id = ENV["LIFF_ID"]
  end
end
