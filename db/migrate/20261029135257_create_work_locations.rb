class CreateWorkLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :work_locations do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.integer :budget_count
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :work_locations, :name, unique: true
  end
end
