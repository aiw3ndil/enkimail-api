class CreateSenders < ActiveRecord::Migration[7.1]
  def change
    create_table :senders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.string :email
      t.string :name

      t.timestamps
    end
  end
end
