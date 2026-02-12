class AddDetailsToEmailEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :email_events, :details, :text
  end
end
