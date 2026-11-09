class Liff::SessionsController < Liff::BaseController
  # POST /liff/session
  # The entry page posts the LIFF ID token as JSON. In development a staff member can be picked directly (dev_user_id).
  def create
    user = find_user

    if user.nil?
      respond_with_error "LINE公式アカウントを友だち追加してから、もう一度開いてください。", :not_found
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
        User.find_by(line_uid: LineIdToken.verify(params[:id_token])["sub"])
      end
    end

    def respond_with_error(message, status)
      respond_to do |format|
        format.html { redirect_to liff_root_path, alert: message }
        format.json { render json: { error: message }, status: status }
      end
    end
end
