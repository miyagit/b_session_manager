class Admin::BaseController < ApplicationController
  layout "admin"

  before_action :authenticate_admin_user!

  private
    # "2026-11" as the first day of the month, or nil.
    def parse_month(value)
      Date.strptime(value, "%Y-%m") if value.present?
    rescue Date::Error
      nil
    end
end
