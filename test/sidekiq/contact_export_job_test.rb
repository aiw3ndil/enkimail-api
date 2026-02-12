require 'test_helper'
require 'csv'
require 'tempfile'

class ContactExportJobTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "exporter@example.com", password: "password", password_confirmation: "password")
    @other_user = User.create!(email: "other@example.com", password: "password", password_confirmation: "password")

    @contact1 = @user.contacts.create!(email: 'user1@example.com', first_name: 'User1', last_name: 'Test', status: 'subscribed')
    @contact2 = @user.contacts.create!(email: 'user2@example.com', first_name: 'User2', last_name: 'Test', status: 'unsubscribed')
    @other_contact = @other_user.contacts.create!(email: 'other@example.com', first_name: 'Other', last_name: 'User', status: 'subscribed')
  end

  teardown do
    @user.contacts.destroy_all
    @other_user.contacts.destroy_all
    @user.destroy
    @other_user.destroy
  end

  test 'should export only the current user\'s contacts to a CSV file' do
    file_path = ContactExportJob.new.perform(@user.id)

    assert File.exist?(file_path), "Exported CSV file does not exist at #{file_path}"

    csv_content = CSV.read(file_path, headers: true)

    assert_equal 2, csv_content.size
    assert_equal ['email', 'first_name', 'last_name', 'status'], csv_content.headers

    emails = csv_content.map { |row| row['email'] }
    assert_includes emails, @contact1.email
    assert_includes emails, @contact2.email
    assert_not_includes emails, @other_contact.email

    File.delete(file_path) # Clean up the generated file
  end
end
