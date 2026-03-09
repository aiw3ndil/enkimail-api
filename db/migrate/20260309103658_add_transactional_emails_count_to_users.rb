class AddTransactionalEmailsCountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :transactional_emails_count, :integer, default: 0
  end
end
