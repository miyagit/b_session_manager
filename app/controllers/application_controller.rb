class ApplicationController < ActionController::Base
  # ブラウザのバージョン制限（allow_browser）は管理画面側（Admin::BaseController, Admin::SessionsController）で行う。
  # LINE ミニアプリは LINE アプリ内ブラウザ（WebView）で開かれ、こちらでバージョンを選べないため、
  # ここで制限すると 406 になるケースがある。
end
