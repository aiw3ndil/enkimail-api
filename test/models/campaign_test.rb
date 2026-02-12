require "test_helper"

class CampaignTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @email_template = email_templates(:one)
    @contact_list = contact_lists(:one)
  end

  test "should be valid with valid attributes" do
    campaign = Campaign.new(
      name: "Test Campaign",
      subject: "Test Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user
    )
    assert campaign.valid?
  end

  test "should not be valid without a name" do
    campaign = Campaign.new(
      subject: "Test Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user
    )
    assert_not campaign.valid?
    assert_includes campaign.errors[:name], "can't be blank"
  end

  test "should not be valid without a subject" do
    campaign = Campaign.new(
      name: "Test Campaign",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user
    )
    assert_not campaign.valid?
    assert_includes campaign.errors[:subject], "can't be blank"
  end

  test "should not be valid without an email_template" do
    campaign = Campaign.new(
      name: "Test Campaign",
      subject: "Test Subject",
      contact_list: @contact_list,
      user: @user
    )
    assert_not campaign.valid?
    assert_includes campaign.errors[:email_template], "must exist"
  end

  test "should not be valid without a contact_list" do
    campaign = Campaign.new(
      name: "Test Campaign",
      subject: "Test Subject",
      email_template: @email_template,
      user: @user
    )
    assert_not campaign.valid?
    assert_includes campaign.errors[:contact_list], "must exist"
  end

  test "status should be draft by default" do
    campaign = Campaign.new(
      name: "Test Campaign",
      subject: "Test Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user
    )
    assert_equal "draft", campaign.status
  end

  test "should be valid with scheduled status and future scheduled_at" do
    campaign = Campaign.new(
      name: "Scheduled Campaign",
      subject: "Scheduled Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user,
      status: :scheduled,
      scheduled_at: 1.day.from_now
    )
    assert campaign.valid?, campaign.errors.full_messages.to_sentence
  end

  test "should not be valid with scheduled status but no scheduled_at" do
    campaign = Campaign.new(
      name: "Scheduled Campaign",
      subject: "Scheduled Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user,
      status: :scheduled,
      scheduled_at: nil
    )
    assert_not campaign.valid?
    assert_includes campaign.errors[:scheduled_at], "can't be blank"
  end

  test "should not be valid with scheduled_at in the past" do
    campaign = Campaign.new(
      name: "Scheduled Campaign",
      subject: "Scheduled Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user,
      status: :scheduled,
      scheduled_at: 1.day.ago
    )
    assert_not campaign.valid?
    assert_includes campaign.errors[:scheduled_at], "must be in the future"
  end

  test "should be valid with sending status" do
    campaign = Campaign.new(
      name: "Sending Campaign",
      subject: "Sending Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user,
      status: :sending
    )
    assert campaign.valid?, campaign.errors.full_messages.to_sentence
  end

  test "status transitions are valid" do
    campaign = Campaign.new(
      name: "Test Campaign",
      subject: "Test Subject",
      email_template: @email_template,
      contact_list: @contact_list,
      user: @user
    )
    assert campaign.draft?

    campaign.scheduled_at = 1.day.from_now
    campaign.scheduled!
    assert campaign.scheduled?

    campaign.sending!
    assert campaign.sending?

    campaign.sent!
    assert campaign.sent?

    campaign.failed!
    assert campaign.failed?
  end
end
