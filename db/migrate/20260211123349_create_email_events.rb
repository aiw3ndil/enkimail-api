class CreateEmailEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :email_events do |t|
      t.integer :event_type, null: false
      t.references :contact, null: false, foreign_key: true
      t.references :campaign, null: true, foreign_key: true
      t.references :email_template, null: true, foreign_key: true
      t.string :url, null: true
      t.string :ip_address, null: true
      t.text :user_agent, null: true
      t.datetime :timestamp, null: false, default: -> { 'NOW()' }

      t.timestamps
    end
  end
end
