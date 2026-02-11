require 'test_helper'
require 'csv'
require 'minitest/mock'

class ContactImportJobTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "test@example.com", password: "password", password_confirmation: "password")
  end

  test 'should import contacts from CSV data' do
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['email', 'first_name', 'last_name', 'status']
      csv << ['john.doe@example.com', 'John', 'Doe', 'subscribed']
      csv << ['jane.doe@example.com', 'Jane', 'Doe', 'subscribed']
    end

    assert_difference('Contact.count', 2) do
      ContactImportJob.new.perform(csv_data, @user.id)
    end

    john = Contact.find_by(email: 'john.doe@example.com')
    assert_not_nil john
    assert_equal 'John', john.first_name
    assert_equal 'Doe', john.last_name
    assert_equal 'subscribed', john.status
    assert_equal @user.id, john.user_id

    jane = Contact.find_by(email: 'jane.doe@example.com')
    assert_not_nil jane
    assert_equal 'Jane', jane.first_name
    assert_equal 'Doe', jane.last_name
    assert_equal 'subscribed', jane.status
    assert_equal @user.id, jane.user_id
  end

  test 'should update existing contacts' do
    existing_contact = @user.contacts.create!(email: 'update.me@example.com', first_name: 'Old', last_name: 'Name', status: 'subscribed')

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['email', 'first_name', 'last_name', 'status']
      csv << ['update.me@example.com', 'Updated', 'Contact', 'unsubscribed']
    end

    assert_no_difference('Contact.count') do
      ContactImportJob.new.perform(csv_data, @user.id)
    end

    existing_contact.reload
    assert_equal 'Updated', existing_contact.first_name
    assert_equal 'Contact', existing_contact.last_name
    assert_equal 'unsubscribed', existing_contact.status
  end

  test 'should handle invalid contact data and log errors' do
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['email', 'first_name', 'last_name', 'status']
      csv << ['invalid-email', 'Invalid', 'Contact', 'subscribed'] # Invalid email
    end

    # Minitest doesn't have `expects` on built-in objects like Rails.logger directly.
    # We can stub the method on the logger or capture output.
    # For now, we'll ensure no contact is created and rely on Rails' internal logging.
    # In a real scenario, you might inject a mock logger or check log files.
    # We can also temporarily reassign Rails.logger to a mock.
    
    mock_logger = Minitest::Mock.new
    mock_logger.expect :error, nil, [String] # Expects an error message string
    
    original_logger = Rails.logger
    Rails.logger = mock_logger
    
    begin
      assert_no_difference('Contact.count') do
        ContactImportJob.new.perform(csv_data, @user.id)
      end
    ensure
      Rails.logger = original_logger # Restore original logger
    end
    
    mock_logger.verify


    assert_nil Contact.find_by(email: 'invalid-email')
  end
end
