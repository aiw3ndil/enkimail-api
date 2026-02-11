class CreateContactLists < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_lists do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :contact_lists, :name, unique: true
  end
end
