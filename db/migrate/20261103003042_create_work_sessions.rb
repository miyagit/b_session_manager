class CreateWorkSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :work_sessions do |t|
      t.references :work_location, null: false, foreign_key: true
      t.date :work_date, null: false
      t.string :team_name
      t.integer :budget_count
      t.string :line_group_id

      t.timestamps
    end
    add_index :work_sessions, :work_date
    add_check_constraint :work_sessions, "budget_count >= 0", name: "work_sessions_budget_count_non_negative"
  end
end
