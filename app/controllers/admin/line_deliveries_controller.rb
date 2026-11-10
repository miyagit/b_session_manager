class Admin::LineDeliveriesController < Admin::BaseController
  # POST /admin/reports/1/line_delivery — post (or re-post) the report to the LINE report group.
  def create
    report = Report.find(params.expect(:report_id))
    LineReportDeliveryJob.perform_later(report)
    redirect_to admin_report_path(report), notice: "LINEへの投稿を開始しました。少し待ってから再読み込みしてください。", status: :see_other
  end
end
