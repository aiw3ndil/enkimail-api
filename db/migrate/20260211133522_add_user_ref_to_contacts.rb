class AddUserRefToContacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :user, foreign_key: true
  end
end
