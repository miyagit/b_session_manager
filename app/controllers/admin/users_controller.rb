class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update destroy ]

  # GET /admin/users
  def index
    @users = User.order(:id)
  end

  # GET /admin/users/new
  def new
    @user = User.new
  end

  # GET /admin/users/1/edit
  def edit
  end

  # POST /admin/users
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "スタッフを登録しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /admin/users/1
  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "スタッフ情報を更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /admin/users/1
  def destroy
    @user.destroy!
    redirect_to admin_users_path, notice: "スタッフを削除しました。", status: :see_other
  end

  private
    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.expect(user: [ :name, :line_uid, :role, :active ])
    end
end
