class AddUserRefToContactLists < ActiveRecord::Migration[7.1]
  def change
    add_reference :contact_lists, :user, foreign_key: true
  end
end
