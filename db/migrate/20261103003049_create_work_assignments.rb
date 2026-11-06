class CreateWorkAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :work_assignments do |t|
      t.references :work_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :target_count, null: false
      t.integer :status, null: false, default: 0
      t.datetime :confirmed_at

      t.timestamps
    end
    add_index :work_assignments, [ :work_session_id, :user_id ], unique: true
    add_check_constraint :work_assignments, "target_count >= 0", name: "work_assignments_target_count_non_negative"
  end
end
