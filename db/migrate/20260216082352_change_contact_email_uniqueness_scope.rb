class ChangeContactEmailUniquenessScope < ActiveRecord::Migration[7.1]
  def change
    remove_index :contacts, :email
    add_index :contacts, [:user_id, :email], unique: true
  end
end
