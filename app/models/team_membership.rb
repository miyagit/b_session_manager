# A staff member's place in a team for the quarter, with a budget (TeamTarget) for each of its months.
class TeamMembership < ApplicationRecord
  belongs_to :team, inverse_of: :team_memberships
  belongs_to :user
  has_many :team_targets, -> { order(:month) }, dependent: :destroy, inverse_of: :team_membership

  accepts_nested_attributes_for :team_targets

  validates :user_id, uniqueness: { scope: :team_id }
  validate :user_is_a_person
  validate :user_in_one_team_per_quarter

  # The member's 予算件数 for the month, nil until it is set.
  def budget_for(month) = team_targets.find { |target| target.month == month }&.budget_count

  # One budget row per month of the quarter, for the form.
  def build_missing_targets
    return if team.nil? || team.starts_on.nil?

    team.months.each { |month| team_targets.build(month: month) unless team_targets.any? { |target| target.month == month } }
  end

  private
    def user_is_a_person
      errors.add(:user_id, "には固定の他社行は選べません") if user&.other_company?
    end

    # A staff member belongs to one team per quarter.
    def user_in_one_team_per_quarter
      return if team.nil? || team.starts_on.nil? || user_id.nil?

      other = TeamMembership.joins(:team).where(teams: { starts_on: team.starts_on }, user_id: user_id).where.not(team_id: team.id).first
      errors.add(:user_id, "は同じ四半期の「#{other.team.name}」にすでに入っています") if other
    end
end
