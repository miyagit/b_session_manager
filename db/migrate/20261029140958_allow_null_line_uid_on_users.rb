class AllowNullLineUidOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :line_uid, true
  end
end
