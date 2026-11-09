class Liff::EntriesController < Liff::BaseController
  # GET /liff — the LIFF endpoint URL. The page initializes the LIFF SDK and posts the ID token to
  # Liff::SessionsController; once the staff member is in the session they go straight to the form.
  def show
    redirect_to new_liff_report_path if current_staff
  end
end
