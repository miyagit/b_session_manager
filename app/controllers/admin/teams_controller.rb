# Teams for a quarter and their monthly progress (TeamProgress). Shifts come from the registered 稼働予定 and results
# from the reports, so only the team, its members and each member's monthly 予算件数 are entered here.
class Admin::TeamsController < Admin::BaseController
  NEW_MEMBER_ROWS = 6
  EXTRA_MEMBER_ROWS = 3

  before_action :set_team, only: %i[ show edit update destroy ]

  # GET /admin/teams
  def index
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @quarter_start = Team.quarter_start(@month)
    @teams = Team.where(starts_on: @quarter_start).order(:id)
    @progresses = @teams.map { |team| TeamProgress.build(team, @month) }
    @monthly_target = MonthlyTarget.for(@month)
  end

  # GET /admin/teams/1
  def show
    requested = parse_month(params[:month])
    @month = if @team.covers?(requested) then requested
    elsif @team.covers?(Date.current.beginning_of_month) then Date.current.beginning_of_month
    else @team.months.first
    end
    @progress = TeamProgress.build(@team, @month)
    @monthly_target = MonthlyTarget.for(@month)
  end

  # GET /admin/teams/new
  def new
    @team = Team.new(starts_on: Team.quarter_start(parse_month(params[:month]) || Date.current))
    prepare_form(NEW_MEMBER_ROWS)
  end

  # GET /admin/teams/1/edit
  def edit
    prepare_form(EXTRA_MEMBER_ROWS)
  end

  # POST /admin/teams
  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to admin_team_path(@team), notice: "チームを登録しました。"
    else
      prepare_form(NEW_MEMBER_ROWS)
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /admin/teams/1
  def update
    # The quarter is fixed once the team exists (the budgets belong to its months).
    if @team.update(team_params.except(:starts_on))
      redirect_to admin_team_path(@team), notice: "チームを更新しました。", status: :see_other
    else
      prepare_form(EXTRA_MEMBER_ROWS)
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /admin/teams/1
  def destroy
    @team.destroy!
    redirect_to admin_teams_path(month: @team.starts_on.strftime("%Y-%m")), notice: "チームを削除しました。", status: :see_other
  end

  private
    def set_team
      @team = Team.includes(team_memberships: [ :user, :team_targets ]).find(params.expect(:id))
    end

    def team_params
      params.expect(team: [ :name, :starts_on,
                            team_memberships_attributes: [ [ :id, :user_id, :_destroy, team_targets_attributes: [ [ :id, :month, :budget_count ] ] ] ] ])
    end

    # Blank member rows to fill in, and a budget field for each month of the quarter on every row.
    def prepare_form(blank_rows)
      blank = @team.team_memberships.count { |membership| membership.new_record? && membership.user_id.blank? }
      (blank_rows - blank).times { @team.team_memberships.build }
      @team.team_memberships.each(&:build_missing_targets)
    end
end
