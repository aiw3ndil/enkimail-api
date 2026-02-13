require 'csv'

class ContactExportJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    contacts = user.contacts

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['email', 'first_name', 'last_name', 'status', 'created_at']
      
      contacts.find_each do |contact|
        csv << [contact.email, contact.first_name, contact.last_name, contact.status, contact.created_at]
      end
    end

    UserMailer.export_contacts_email(user, csv_data).deliver_now
  end
end
