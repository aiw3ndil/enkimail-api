require 'test_helper'

class WebhookEndpointTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @webhook_endpoint = WebhookEndpoint.new(url: "https://example.com", events: ["sent"], user: @user)
  end

  test "should be valid" do
    assert @webhook_endpoint.valid?
  end

  test "url should be present" do
    @webhook_endpoint.url = " "
    assert_not @webhook_endpoint.valid?
  end

  test "url should be a valid URL" do
    @webhook_endpoint.url = "invalid_url"
    assert_not @webhook_endpoint.valid?
  end

  test "events should be present" do
    @webhook_endpoint.events = nil
    assert_not @webhook_endpoint.valid?
  end

  test "should generate secret on create" do
    @webhook_endpoint.save
    assert_not_nil @webhook_endpoint.secret
  end
end
