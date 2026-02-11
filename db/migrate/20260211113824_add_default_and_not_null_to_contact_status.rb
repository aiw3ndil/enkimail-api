class AddDefaultAndNotNullToContactStatus < ActiveRecord::Migration[7.1]
  def change
    change_column_null :contacts, :status, false, 0
    change_column_default :contacts, :status, from: nil, to: 0
  end
end
