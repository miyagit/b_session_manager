class CreateMonthlyTargets < ActiveRecord::Migration[8.1]
  def change
    # Targets shared by every team in a month: the card rate (目標カード率).
    create_table :monthly_targets do |t|
      t.date :month, null: false # first day of the month
      t.integer :card_rate, null: false # percentage

      t.timestamps
    end
    add_index :monthly_targets, :month, unique: true
    add_check_constraint :monthly_targets, "card_rate BETWEEN 0 AND 100", name: "monthly_targets_card_rate_percentage"
  end
end
