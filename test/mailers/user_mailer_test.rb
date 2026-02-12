require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "send_generic_email" do
    # Create dummy data for the test
    user = User.create!(email: "mailer_test@example.com", password: "password", password_confirmation: "password")
    template = user.email_templates.create!(name: "test_template", subject: "Hello", body: "Body")
    contact = user.contacts.create!(email: "recipient@example.com", status: "subscribed")
    
    mail = UserMailer.send_generic_email("recipient@example.com", template.name, contact.id, { name: "Test User" }, nil, template.id)
    
    assert_equal "Hello", mail.subject
    assert_equal ["recipient@example.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Body", mail.body.encoded
  end

end
