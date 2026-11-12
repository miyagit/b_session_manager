class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    # A group of staff for one quarter, followed against monthly acquisition budgets on the team screen.
    create_table :teams do |t|
      t.string :name, null: false
      t.date :starts_on, null: false # first day of the quarter: Jan 1, Apr 1, Jul 1 or Oct 1

      t.timestamps
    end
    add_index :teams, [ :starts_on, :name ], unique: true
  end
end
