# First-time linking: a verified LINE account picks the pre-registered staff member it belongs to.
class Liff::LinksController < Liff::BaseController
  CLAIMS_TTL = 30.minutes

  before_action :require_line_claims

  # GET /liff/link — pick your name from the staff members not linked to LINE yet; with user_id, confirm the pick.
  def show
    @candidates = unlinked_staff
    @candidate = @candidates.find { |user| user.id.to_s == params[:user_id] }
  end

  # POST /liff/link — link the LINE account to the chosen staff member and sign in.
  def create
    user = unlinked_staff.find { |candidate| candidate.id.to_s == params[:user_id] }
    return redirect_to liff_link_path, alert: "そのスタッフは選べません。もう一度選んでください。" if user.nil?

    user.update!(line_uid: @line_claims["sub"], avatar_url: user.avatar_url.presence || @line_claims["picture"])
    reset_session
    session[:liff_user_id] = user.id
    redirect_to new_liff_report_path, notice: "#{user.name}さんとして LINE と連携しました。"
  end

  private
    def unlinked_staff
      @unlinked_staff ||= User.where(is_active: true, line_uid: nil).order(:name).to_a
    end

    # Only right after the LINE account was verified, and never for someone who is already signed in.
    def require_line_claims
      return redirect_to new_liff_report_path if current_staff

      @line_claims = session[:liff_line_claims]
      return if @line_claims.present? && @line_claims["verified_at"].to_i >= CLAIMS_TTL.ago.to_i

      session.delete(:liff_line_claims)
      redirect_to liff_root_path
    end
end
