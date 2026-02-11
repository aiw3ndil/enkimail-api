require 'csv'

class ContactImportJob
  include Sidekiq::Job

  def perform(csv_data, user_id)
    user = User.find(user_id)
    # This assumes your CSV has headers like 'email', 'first_name', 'last_name', 'status'
    CSV.parse(csv_data, headers: true) do |row|
      contact_data = row.to_h.slice('email', 'first_name', 'last_name', 'status')
      contact = user.contacts.find_or_initialize_by(email: contact_data['email'])
      contact.assign_attributes(contact_data)

      if contact.save
        # Log success or do nothing
      else
        # Log error or send notification
        Rails.logger.error "Failed to import contact #{contact_data['email']}: #{contact.errors.full_messages.to_sentence}"
      end
    end
  end
end
