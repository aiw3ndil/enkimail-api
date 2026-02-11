require 'csv'
require 'tempfile'

class ContactExportJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find(user_id)
    contacts = user.contacts

    # Define headers for the CSV
    headers = ['email', 'first_name', 'last_name', 'status']

    Tempfile.create(['contacts_export', '.csv']) do |file|
      CSV(file, headers: true) do |csv|
        csv << headers
        contacts.each do |contact|
          csv << contact.attributes.slice('email', 'first_name', 'last_name', 'status').values
        end
      end
      # Return the file path for testing purposes
      file.path
    end
  end
end
