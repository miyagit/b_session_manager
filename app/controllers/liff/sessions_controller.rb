class Liff::SessionsController < Liff::BaseController
  # POST /liff/session
  # The entry page posts the LIFF ID token as JSON. In development a staff member can be picked directly (dev_user_id).
  def create
    user = find_user

    if user.nil?
      respond_with_error "スタッフが見つかりません。管理者に連絡してください。", :not_found
    elsif !user.is_active
      respond_with_error "このアカウントは無効になっています。管理者に連絡してください。", :forbidden
    else
      reset_session
      session[:liff_user_id] = user.id
      respond_to do |format|
        format.html { redirect_to new_liff_report_path }
        format.json { render json: { redirect_to: new_liff_report_path } }
      end
    end
  rescue LineIdToken::Error => e
    respond_with_error "LINEの認証に失敗しました（#{e.message}）。LIFFを開き直してください。", :unauthorized
  end

  # DELETE /liff/session
  def destroy
    reset_session
    redirect_to liff_root_path, status: :see_other
  end

  private
    def find_user
      if Rails.env.development? && params[:dev_user_id].present?
        User.find_by(id: params[:dev_user_id])
      else
        find_or_create_line_user(LineIdToken.verify(params[:id_token]))
      end
    end

    # A LINE account opening the LIFF for the first time becomes a staff member right away, so onboarding doesn't
    # depend on the follow webhook. Until an admin gives them a shift they see "no shifts today".
    def find_or_create_line_user(claims)
      User.find_or_create_by!(line_uid: claims["sub"]) do |user|
        user.name = claims["name"].presence || "LINEユーザー"
        user.avatar_url = claims["picture"]
      end
    end

    def respond_with_error(message, status)
      respond_to do |format|
        format.html { redirect_to liff_root_path, alert: message }
        format.json { render json: { error: message }, status: status }
      end
    end
end
