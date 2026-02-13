class CreateDomains < ActiveRecord::Migration[7.1]
  def change
    create_table :domains do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.integer :status
      t.text :dkim_private_key
      t.text :dkim_public_key
      t.string :dkim_selector
      t.string :verification_error

      t.timestamps
    end
  end
end
