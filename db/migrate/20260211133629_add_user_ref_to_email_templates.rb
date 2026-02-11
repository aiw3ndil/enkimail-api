class AddUserRefToEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    add_reference :email_templates, :user, foreign_key: true
  end
end
