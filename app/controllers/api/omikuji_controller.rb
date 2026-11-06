# ミニアプリの画面からおみくじを引く API
class Api::OmikujiController < ApplicationController
  def create
    result = Omikuji.draw

    render json: { name: result.name, message: result.message, text: result.to_text }
  end
end
