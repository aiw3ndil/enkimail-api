class AddVerificationFieldsToDomains < ActiveRecord::Migration[7.1]
  def change
    add_column :domains, :verification_token, :string
    add_index :domains, :verification_token
    add_column :domains, :verification_sent_at, :datetime
    add_column :domains, :verified_at, :datetime
    add_column :domains, :verification_attempts, :integer, default: 0, null: false

  end
end
