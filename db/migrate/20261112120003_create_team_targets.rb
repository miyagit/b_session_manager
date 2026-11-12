class CreateTeamTargets < ActiveRecord::Migration[8.1]
  def change
    # A team member's acquisition budget (予算件数) for one month of the team's quarter.
    create_table :team_targets do |t|
      t.references :team_membership, null: false, foreign_key: true
      t.date :month, null: false # first day of the month
      t.integer :budget_count # nil until the budget is decided

      t.timestamps
    end
    add_index :team_targets, [ :team_membership_id, :month ], unique: true
    add_check_constraint :team_targets, "budget_count >= 0", name: "team_targets_budget_count_non_negative"
  end
end
