class CreateWorkRecords < ActiveRecord::Migration[8.1]
  def change
    # Hours actually worked on a shift (overtime or leaving early), entered with the final report.
    # Cinema shifts have fixed hours and get no record.
    create_table :work_records do |t|
      t.references :shift, null: false, foreign_key: true, index: { unique: true }
      t.time :started_at, null: false
      t.time :ended_at, null: false

      t.timestamps
    end
  end
end
