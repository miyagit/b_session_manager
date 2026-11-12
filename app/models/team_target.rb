# A team member's acquisition budget (予算件数) for one month of the team's quarter.
class TeamTarget < ApplicationRecord
  belongs_to :team_membership, inverse_of: :team_targets

  validates :month, presence: true, uniqueness: { scope: :team_membership_id }
  validates :budget_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :month_within_quarter

  private
    def month_within_quarter
      team = team_membership&.team
      return if month.nil? || team.nil? || team.covers?(month)

      errors.add(:month, "はチームの四半期の中の月にしてください")
    end
end
