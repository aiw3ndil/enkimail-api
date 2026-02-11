class CreateContactListMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_list_memberships do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :contact_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
