class Admin::WorkLocationsController < Admin::BaseController
  before_action :set_work_location, only: %i[ edit update ]

  def index
    @category = params[:category].presence_in(WorkLocation.categories.keys)
    @category_counts = WorkLocation.group(:category).count
    @work_locations = WorkLocation.order(:id)
    @work_locations = @work_locations.where(category: @category) if @category
  end

  def new
    @work_location = WorkLocation.new
  end

  def edit
  end

  def create
    @work_location = WorkLocation.new(work_location_params)

    if @work_location.save
      redirect_to admin_work_locations_path, notice: "稼働場所を登録しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @work_location.update(work_location_params)
      redirect_to admin_work_locations_path, notice: "稼働場所を更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_work_location
    @work_location = WorkLocation.find(params.expect(:id))
  end

  def work_location_params
    params.expect(work_location: [ :name, :category, :budget_count ])
  end
end
