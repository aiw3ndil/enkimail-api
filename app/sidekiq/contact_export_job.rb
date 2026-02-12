require 'csv'
require 'tempfile'

class ContactExportJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find(user_id)
    contacts = user.contacts

    # Define headers for the CSV
    headers = ['email', 'first_name', 'last_name', 'status']

    # Create a unique filename for the export
    filename = "contacts_export_#{user.id}_#{Time.current.to_i}.csv"
    filepath = Rails.root.join('tmp', 'exports', filename)

    CSV.open(filepath, "wb", headers: true) do |csv|
      csv << headers
      contacts.each do |contact|
        csv << contact.attributes.slice('email', 'first_name', 'last_name', 'status').values
      end
    end
    # Return the file path for testing purposes
    filepath.to_s
  end
end
