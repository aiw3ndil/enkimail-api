require 'csv'

class ContactImportJob < ApplicationJob
  queue_as :default

  def perform(file_content, user_id)
    user = User.find(user_id)
    
    CSV.parse(file_content, headers: true) do |row|
      contact_attributes = row.to_hash.slice('email', 'first_name', 'last_name', 'status')
      
      # Skip if email is missing
      next unless contact_attributes['email'].present?

      # Find or Initialize contact by email for this user
      contact = user.contacts.find_or_initialize_by(email: contact_attributes['email'])
      
      # Update attributes
      contact.first_name = contact_attributes['first_name'] if contact_attributes['first_name'].present?
      contact.last_name = contact_attributes['last_name'] if contact_attributes['last_name'].present?
      contact.status = contact_attributes['status'] if contact_attributes['status'].present?
      
      contact.save
    rescue StandardError => e
      Rails.logger.error "Failed to import contact row: #{row.inspect}. Error: #{e.message}"
    end
  end
end
