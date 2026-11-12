class AllowReportsPerStaff < ActiveRecord::Migration[8.1]
  # Reports are filed per staff member: several start / interim (same slot) / final reports may exist for one booth
  # day, each covering the staff whose rows were filled in. A start report records whose targets it set.
  def up
    remove_index :reports, name: "index_reports_on_work_session_and_interim_slot"
    remove_index :reports, name: "index_reports_on_work_session_and_single_type"
    add_index :reports, [ :work_session_id, :report_type ]
    add_column :reports, :covered_user_ids, :bigint, array: true, null: false, default: []
    # Start reports filed so far declared the targets of everyone on the booth.
    execute <<~SQL
      UPDATE reports SET covered_user_ids = booth.user_ids
      FROM (SELECT work_session_id, array_agg(user_id ORDER BY id) AS user_ids FROM shifts GROUP BY work_session_id) booth
      WHERE reports.work_session_id = booth.work_session_id AND reports.report_type = 'start'
    SQL
  end

  def down
    remove_column :reports, :covered_user_ids
    remove_index :reports, [ :work_session_id, :report_type ]
    add_index :reports, [ :work_session_id, :report_slot ], unique: true, where: "report_type = 'interim'", name: "index_reports_on_work_session_and_interim_slot"
    add_index :reports, [ :work_session_id, :report_type ], unique: true, where: "report_type <> 'interim'", name: "index_reports_on_work_session_and_single_type"
  end
end
