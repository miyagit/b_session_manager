# The month's target card rate, shared by every team; edited from the team list.
class Admin::MonthlyTargetsController < Admin::BaseController
  # PATCH /admin/monthly_target?month=2026-11
  def update
    month = parse_month(params[:month]) || Date.current.beginning_of_month
    monthly_target = MonthlyTarget.for(month)

    if monthly_target.update(params.expect(monthly_target: [ :card_rate ]))
      redirect_to admin_teams_path(month: month.strftime("%Y-%m")), notice: "#{month.month}月の目標カード率を保存しました。", status: :see_other
    else
      redirect_to admin_teams_path(month: month.strftime("%Y-%m")), alert: monthly_target.errors.full_messages.join("。"), status: :see_other
    end
  end
end
