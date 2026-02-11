class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.integer :status, default: 0, null: false
      t.jsonb :custom_attributes

      t.timestamps
    end
    add_index :contacts, :email, unique: true
  end
end
