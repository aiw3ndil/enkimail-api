class CreateCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :campaigns do |t|
      t.string :name, null: false
      t.string :subject, null: false
      t.integer :status, default: 0, null: false
      t.references :email_template, null: false, foreign_key: true
      t.references :contact_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
