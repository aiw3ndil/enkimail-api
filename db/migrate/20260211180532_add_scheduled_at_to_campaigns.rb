class AddScheduledAtToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_column :campaigns, :scheduled_at, :datetime
  end
end
