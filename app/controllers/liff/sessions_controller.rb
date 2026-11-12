class Liff::SessionsController < Liff::BaseController
  # POST /liff/session
  # The entry page posts the LIFF ID token as JSON. A LINE account no staff member is linked to yet is sent to the
  # linking screen (Liff::LinksController) instead of being registered automatically.
  # In development a staff member, or an unlinked fake LINE account, can be picked directly.
  def create
    if Rails.env.development? && params[:dev_user_id].present?
      sign_in(User.find_by(id: params[:dev_user_id]))
    else
      claims = development_claims || LineIdToken.verify(params[:id_token]).slice("sub", "name", "picture")
      user = User.find_by(line_uid: claims["sub"])
      user ? sign_in(user) : start_linking(claims)
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
    def sign_in(user)
      if user.nil?
        respond_with_error "スタッフが見つかりません。管理者に連絡してください。", :not_found
      elsif !user.is_active
        respond_with_error "このアカウントは無効になっています。管理者に連絡してください。", :forbidden
      else
        reset_session
        session[:liff_user_id] = user.id
        respond_with_redirect new_liff_report_path
      end
    end

    # The verified LINE claims stay in the session (briefly) until the staff member picks their name.
    def start_linking(claims)
      reset_session
      session[:liff_line_claims] = claims.merge("verified_at" => Time.current.to_i)
      respond_with_redirect liff_link_path
    end

    # development only: pretend to be a LINE account that isn't linked to any staff member yet
    def development_claims
      return unless Rails.env.development? && params[:dev_line_sub].present?

      { "sub" => params[:dev_line_sub], "name" => "開発用LINEユーザー", "picture" => nil }
    end

    def respond_with_redirect(path)
      respond_to do |format|
        format.html { redirect_to path }
        format.json { render json: { redirect_to: path } }
      end
    end

    def respond_with_error(message, status)
      respond_to do |format|
        format.html { redirect_to liff_root_path, alert: message }
        format.json { render json: { error: message }, status: status }
      end
    end
end
