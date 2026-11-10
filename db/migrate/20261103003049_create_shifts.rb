class CreateShifts < ActiveRecord::Migration[8.1]
  def change
    create_table :shifts do |t|
      t.references :work_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :shift_type, null: false
      t.integer :target_acquired_count # set by the staff in the start report
      t.integer :target_approach_count
      t.time :started_at # full-day shifts only: start time declared in the start report (other shifts have fixed hours)

      t.timestamps
    end
    add_index :shifts, [ :work_session_id, :user_id ], unique: true
    add_check_constraint :shifts, "target_acquired_count >= 0", name: "shifts_target_acquired_count_non_negative"
    add_check_constraint :shifts, "target_approach_count >= 0", name: "shifts_target_approach_count_non_negative"
  end
end
