class Admin::SessionsController < Devise::SessionsController
  layout "admin"

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def after_sign_in_path_for(resource)
      stored_location_for(resource) || admin_root_path
    end

    def after_sign_out_path_for(_resource_or_scope)
      new_admin_user_session_path
    end
end
