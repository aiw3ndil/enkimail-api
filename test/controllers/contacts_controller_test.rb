require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    @user = users(:one) # Using fixture user
    @auth_headers = { 'Authorization' => "Bearer #{@user.api_key}" }
  end

  test "should queue ContactImportJob on POST /api/v1/contacts/import with valid CSV" do
    csv_content = "email,first_name,last_name,status\nimport1@example.com,Import1,User,subscribed\n"

    file_for_upload = ActionDispatch::Http::UploadedFile.new(
      tempfile: StringIO.new(csv_content),
      filename: 'contacts.csv',
      type: 'text/csv'
    )
    file_for_upload.tempfile.rewind # Rewind the StringIO for reading
    
    assert_difference('Sidekiq::Worker.jobs.size', 1) do
      post import_api_v1_contacts_path, headers: @auth_headers, params: { file: file_for_upload }
    end
    assert_response :accepted
    assert_equal 'Contact import has been queued.', json_response['message']

    job = Sidekiq::Worker.jobs.last
    assert_equal 'ContactImportJob', job['class']
    assert_equal [csv_content, @user.id], job['args']
  end

  test "should return error if no CSV file is provided on POST /api/v1/contacts/import" do
    assert_no_difference('Sidekiq::Worker.jobs.size') do
      post import_api_v1_contacts_path, headers: @auth_headers
    end
    assert_response :unprocessable_entity
    assert_equal 'No CSV file provided.', json_response['error']
  end

  test "should queue ContactExportJob on GET /api/v1/contacts/export" do
    assert_difference('Sidekiq::Worker.jobs.size', 1) do
      get export_api_v1_contacts_path, headers: @auth_headers
    end
    assert_response :accepted
    assert_equal 'Contact export has been queued. You will receive an email with the download link shortly.', json_response['message']

    job = Sidekiq::Worker.jobs.last
    assert_equal 'ContactExportJob', job['class']
    assert_equal [@user.id], job['args']
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
