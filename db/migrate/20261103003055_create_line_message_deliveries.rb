class CreateLineMessageDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :line_message_deliveries do |t|
      t.references :report, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.string :message_id
      t.text :error_message
      t.datetime :sent_at

      t.timestamps
    end
  end
end
