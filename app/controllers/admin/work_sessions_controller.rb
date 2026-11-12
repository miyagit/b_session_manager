class Admin::WorkSessionsController < Admin::BaseController
  BLANK_SHIFT_ROWS = 3

  before_action :set_work_session, only: %i[ edit update destroy ]

  # GET /admin/work_sessions
  def index
    @date = parse_date(params[:date]) || Date.current
    @work_sessions = WorkSession.includes(:work_location, shifts: [ :user, :work_record ], reports: :report_results)
      .where(work_date: @date).order(:work_location_id)
  end

  # GET /admin/work_sessions/new
  def new
    @work_session = WorkSession.new(work_date: parse_date(params[:date]) || Date.current)
    build_blank_shifts
  end

  # GET /admin/work_sessions/1/edit
  def edit
    build_blank_shifts
  end

  # POST /admin/work_sessions
  def create
    @work_session = WorkSession.new(work_session_params)

    if @work_session.save
      redirect_to admin_work_sessions_path(date: @work_session.work_date), notice: "稼働予定を登録しました。"
    else
      build_blank_shifts
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /admin/work_sessions/1
  def update
    if @work_session.update(work_session_params)
      redirect_to admin_work_sessions_path(date: @work_session.work_date), notice: "稼働予定を更新しました。", status: :see_other
    else
      build_blank_shifts
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /admin/work_sessions/1
  def destroy
    if @work_session.destroy
      redirect_to admin_work_sessions_path(date: @work_session.work_date), notice: "稼働予定を削除しました。", status: :see_other
    else
      redirect_to edit_admin_work_session_path(@work_session), alert: "報告がある稼働予定は削除できません。", status: :see_other
    end
  end

  private
    def set_work_session
      @work_session = WorkSession.includes(shifts: :user, reports: :report_results).find(params.expect(:id))
    end

    def work_session_params
      params.expect(work_session: [ :work_date, :work_location_id, :budget_count,
                                    shifts_attributes: [ [ :id, :user_id, :shift_type, :_destroy ] ] ])
    end

    def parse_date(value)
      Date.iso8601(value) if value.present?
    rescue Date::Error
      nil
    end

    def build_blank_shifts
      blank_rows = @work_session.shifts.count { |shift| shift.new_record? && shift.user_id.blank? }
      (BLANK_SHIFT_ROWS - blank_rows).times { @work_session.shifts.build(shift_type: :full_day) }
    end
end
