class CreateReportResults < ActiveRecord::Migration[8.1]
  def change
    create_table :report_results do |t|
      t.references :report, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :acquired_count, null: false
      t.integer :approach_count
      t.integer :card_count

      t.timestamps
    end
    add_index :report_results, [ :report_id, :user_id ], unique: true
    add_check_constraint :report_results, "acquired_count >= 0", name: "report_results_acquired_count_non_negative"
    add_check_constraint :report_results, "approach_count >= 0", name: "report_results_approach_count_non_negative"
    add_check_constraint :report_results, "card_count >= 0", name: "report_results_card_count_non_negative"
  end
end
