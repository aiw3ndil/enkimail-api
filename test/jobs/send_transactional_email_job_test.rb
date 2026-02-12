require "test_helper"

class SendTransactionalEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "queues the job" do
    assert_enqueued_with(job: SendTransactionalEmailJob) do
      SendTransactionalEmailJob.perform_later(to: "test@example.com", subject: "Test", body: "Hello")
    end
  end

  test "sends email" do
    assert_emails 1 do
      SendTransactionalEmailJob.perform_now(to: "test@example.com", subject: "Test", body: "Hello")
    end
  end
end
