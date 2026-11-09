# Screens opened inside LINE through LIFF. The staff member is identified once by their LINE ID token
# (Liff::SessionsController) and then kept in the session.
class Liff::BaseController < ApplicationController
  layout "liff"

  helper_method :current_staff, :liff_id

  private
    def current_staff
      return @current_staff if defined?(@current_staff)

      @current_staff = session[:liff_user_id] && User.find_by(id: session[:liff_user_id], is_active: true)
    end

    def require_staff
      redirect_to liff_root_path unless current_staff
    end

    def liff_id
      Rails.configuration.x.liff.id
    end
end
