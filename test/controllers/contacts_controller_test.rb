require "test_helper"
require 'sidekiq/testing' # Load Sidekiq testing helpers

class ContactsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  setup do
    @user = User.create!(email: "test_controller@example.com", password: "password", password_confirmation: "password")
    @auth_headers = { 'Authorization' => "Bearer #{@user.api_key}" }
    Sidekiq::Testing.fake! # Enable fake Sidekiq for testing
  end

  teardown do
    Sidekiq::Testing.inline! # Reset Sidekiq testing mode
  end

  test "should queue ContactImportJob on POST /api/v1/contacts/import with valid CSV" do
    csv_content = CSV.generate(headers: true) do |csv|
      csv << ['email', 'first_name', 'last_name', 'status']
      csv << ['import1@example.com', 'Import1', 'User', 'subscribed']
    end

    # Create a new StringIO for the upload, and another for the assertion
    file_for_upload = ActionDispatch::Http::UploadedFile.new(
      tempfile: StringIO.new(csv_content),
      filename: 'contacts.csv',
      type: 'text/csv'
    )
    
    assert_enqueued_with(job: ContactImportJob, args: [csv_content, @user.id]) do
      post import_api_v1_contacts_path, headers: @auth_headers, params: { file: file_for_upload }
    end
    assert_response :accepted
    assert_equal 'Contact import has been queued.', json_response['message']
  end

  test "should return error if no CSV file is provided on POST /api/v1/contacts/import" do
    post import_api_v1_contacts_path, headers: @auth_headers
    assert_response :unprocessable_entity
    assert_equal 'No CSV file provided.', json_response['error']
  end

  test "should queue ContactExportJob on GET /api/v1/contacts/export" do
    assert_enqueued_with(job: ContactExportJob, args: [@user.id]) do
      get export_api_v1_contacts_path, headers: @auth_headers
    end
    assert_response :accepted
    assert_equal 'Contact export has been queued. You will receive an email with the download link shortly.', json_response['message']
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
