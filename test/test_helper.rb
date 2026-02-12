ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "sidekiq/testing" # Required for Sidekiq::Testing
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    Rails.application.routes.default_url_options = { host: 'localhost', port: 3001 }

    setup do
      Sidekiq::Testing.fake!
      Sidekiq::Worker.clear_all
    end

    teardown do
      Sidekiq::Worker.clear_all
    end
  end
end
