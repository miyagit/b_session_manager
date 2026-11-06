class Admin::BaseController < ApplicationController
  layout "admin"

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_admin_user!
end
