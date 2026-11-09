class CreateWorkSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :work_sessions do |t|
      t.references :work_location, null: false, foreign_key: true
      t.date :work_date, null: false
      t.integer :budget_count, null: false

      t.timestamps
    end
    add_index :work_sessions, :work_date
    add_index :work_sessions, [ :work_location_id, :work_date ], unique: true
    add_check_constraint :work_sessions, "budget_count >= 0", name: "work_sessions_budget_count_non_negative"
  end
end
