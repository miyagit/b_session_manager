class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :work_session, null: false, foreign_key: true
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }
      t.string :report_type, null: false
      t.integer :report_slot
      t.integer :audience_count # cinema booths only: the day's moviegoers, entered with the final report

      t.timestamps
    end
    # One interim report per time slot; one start and one final report per work session.
    add_index :reports, [ :work_session_id, :report_slot ], unique: true, where: "report_type = 'interim'", name: "index_reports_on_work_session_and_interim_slot"
    add_index :reports, [ :work_session_id, :report_type ], unique: true, where: "report_type <> 'interim'", name: "index_reports_on_work_session_and_single_type"
    add_check_constraint :reports, "report_slot IS NULL OR report_slot IN (13, 16, 19)", name: "reports_report_slot_fixed_times"
    add_check_constraint :reports, "(report_type = 'interim') = (report_slot IS NOT NULL)", name: "reports_report_slot_only_for_interim"
    add_check_constraint :reports, "audience_count >= 0", name: "reports_audience_count_non_negative"
  end
end
