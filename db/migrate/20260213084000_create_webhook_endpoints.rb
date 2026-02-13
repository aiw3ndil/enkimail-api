class CreateWebhookEndpoints < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_endpoints do |t|
      t.references :user, null: false, foreign_key: true
      t.string :url, null: false
      t.jsonb :events, default: []
      t.boolean :active, default: true
      t.string :secret

      t.timestamps
    end
  end
end
