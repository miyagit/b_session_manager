class Admin::LineLinksController < Admin::BaseController
  # DELETE /admin/users/1/line_link — unlink the LINE account so the staff member picks their name again next time.
  def destroy
    user = User.find(params.expect(:user_id))
    user.update!(line_uid: nil)
    redirect_to edit_admin_user_path(user), notice: "LINE連携を解除しました。次に LIFF を開いたときに名前を選び直せます。", status: :see_other
  end
end
