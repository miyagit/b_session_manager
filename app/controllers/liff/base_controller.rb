# Screens opened inside LINE through LIFF. The staff member is identified once by their LINE ID token
# (Liff::SessionsController) and then kept in the session.
class Liff::BaseController < ApplicationController
  layout "liff"

  helper_method :current_staff, :liff_id

  private
    def current_staff
      return @current_staff if defined?(@current_staff)

      user = session[:liff_user_id] && User.find_by(id: session[:liff_user_id], is_active: true)
      # A session opened through LINE is only valid while the staff member is still linked to that LINE account
      # (development logins carry no LINE account).
      user = nil if user && session[:liff_line_uid].present? && user.line_uid != session[:liff_line_uid]
      @current_staff = user
    end

    def require_staff
      redirect_to liff_root_path unless current_staff
    end

    def liff_id
      Rails.configuration.x.liff.id
    end
end
