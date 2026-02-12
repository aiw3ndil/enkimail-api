require "test_helper"

class CampaignSenderWorkerTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @email_template = email_templates(:one)
    
    # Create a fresh contact list for this test to avoid fixture conflicts
    @contact_list = ContactList.create!(name: "Test List #{SecureRandom.hex(4)}", user: @user)
    
    # Create fresh contacts for this test to avoid fixture conflicts
    @contact1 = Contact.create!(email: "test_contact1_#{SecureRandom.hex(4)}@example.com", user: @user, status: :subscribed)
    @contact2 = Contact.create!(email: "test_contact2_#{SecureRandom.hex(4)}@example.com", user: @user, status: :subscribed)

    @contact_list.contacts << @contact1
    @contact_list.contacts << @contact2
  end

  teardown do
    @contact_list.destroy
    @contact1.destroy
    @contact2.destroy
  end

  test "should enqueue EmailSenderWorker for each contact in a campaign" do
    campaign = campaigns(:draft)
    campaign.update(status: :sending) # Simulate controller setting status to sending



    initial_job_count = Sidekiq::Worker.jobs.size
    CampaignSenderWorker.new.perform(campaign.id)
    assert_equal initial_job_count + @contact_list.contacts.count, Sidekiq::Worker.jobs.size

    # Verify enqueued jobs
    enqueued_jobs = Sidekiq::Worker.jobs.last(@contact_list.contacts.count)
    enqueued_jobs.each_with_index do |job, i|
      expected_contact = @contact_list.contacts[i]
      assert_equal 'EmailSenderWorker', job['class']
      assert_equal [expected_contact.email, @email_template.name, { "user_name" => expected_contact.first_name, "user_email" => expected_contact.email, "campaign_name" => campaign.name }, expected_contact.id, campaign.id, @email_template.id], job['args']
    end

    campaign.reload
    assert campaign.sent?
  end

  test "should set campaign status to sent after successful processing" do
    campaign = campaigns(:draft)
    campaign.update(status: :sending) # Simulate controller setting status to sending

    CampaignSenderWorker.new.perform(campaign.id)
    campaign.reload
    assert campaign.sent?
  end

  test "should set campaign status to failed if an error occurs" do
    campaign = campaigns(:draft)
    campaign.update(status: :sending) # Simulate controller setting status to sending

    @contact_list.contacts << contacts(:one) # Ensure contacts are present

    # Simulate an error within the worker
    EmailSenderWorker.stub :perform_async, ->(*_args) { raise StandardError, "Simulated error" } do
      CampaignSenderWorker.new.perform(campaign.id)
    end

    campaign.reload
    assert campaign.failed?
  end

  test "should not process if campaign does not exist" do
    initial_job_count = Sidekiq::Worker.jobs.size
    CampaignSenderWorker.new.perform(-1) # Non-existent campaign ID
    assert_equal initial_job_count, Sidekiq::Worker.jobs.size # No jobs should be enqueued
  end

  test "should handle scheduled campaigns" do
    campaign = campaigns(:scheduled) # Campaign with status 'scheduled'
    
    # Manually set scheduled_at for the test since fixture might be slightly off
    campaign.update(scheduled_at: 1.minute.from_now)
    @contact_list.contacts << contacts(:one) # Ensure contacts are present
    @contact_list.contacts << contacts(:two)

    initial_job_count = Sidekiq::Worker.jobs.size
    # When Sidekiq picks up a scheduled job, it performs it like an async job
    CampaignSenderWorker.new.perform(campaign.id)
    assert_equal initial_job_count + @contact_list.contacts.count, Sidekiq::Worker.jobs.size

    campaign.reload
    assert campaign.sent?
  end
end
