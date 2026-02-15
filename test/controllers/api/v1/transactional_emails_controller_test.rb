require "test_helper"

module Api
  module V1
    class TransactionalEmailsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @headers = { "Authorization" => "Bearer #{@user.api_key}" }
      end

      test "should create transactional email job" do
        assert_enqueued_with(job: SendTransactionalEmailJob) do
          post api_v1_transactional_emails_url, params: {
            to: "test@example.com",
            subject: "Test Subject",
            body: "Test Body"
          }, headers: @headers
        end

        assert_response :accepted
      end

      test "should use verified sender if from param is missing" do
        # Ensure user has a verified sender (from fixtures)
        assert_enqueued_with(job: SendTransactionalEmailJob) do
          post api_v1_transactional_emails_url, params: {
            to: "test@example.com",
            subject: "Test Subject",
            body: "Test Body"
          }, headers: @headers
        end

        assert_response :accepted
        
        # Verify the job args contain the correct sender email
        enqueued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.last
        assert_equal "sender@example.com", enqueued_job[:args][0]["from"]
      end

      test "should return error if missing parameters" do
        post api_v1_transactional_emails_url, params: {
          to: "test@example.com"
        }, headers: @headers

        assert_response :unprocessable_entity
      end
    end
  end
end
