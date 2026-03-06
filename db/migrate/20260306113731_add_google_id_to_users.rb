class AddGoogleIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :google_id, :string
    add_index :users, :google_id
  end
end
