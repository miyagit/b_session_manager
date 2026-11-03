class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :work_session, null: false, foreign_key: true
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }
      t.string :report_type, null: false
      t.integer :report_slot, null: false
      t.datetime :reported_at, null: false

      t.timestamps
    end
    add_index :reports, [ :work_session_id, :report_slot ], unique: true
    add_check_constraint :reports, "report_slot IN (13, 16, 19, 22)", name: "reports_report_slot_fixed_times"
  end
end
