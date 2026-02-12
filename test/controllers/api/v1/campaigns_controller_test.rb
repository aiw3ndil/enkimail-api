require "test_helper"

class Api::V1::CampaignsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers
  setup do
    @user = users(:one) # Assuming a user fixture exists
    @auth_headers = { "Authorization" => "Bearer " + @user.api_key }
    @campaign = campaigns(:draft) # Use a draft campaign fixture
    @email_template = email_templates(:one)
    @contact_list = contact_lists(:one)
  end

  test "should get index" do
    get api_v1_campaigns_url, headers: @auth_headers, as: :json
    assert_response :success
    assert_equal Campaign.count, json_response.count
  end

  test "should show campaign" do
    get api_v1_campaign_url(@campaign), headers: @auth_headers, as: :json
    assert_response :success
    assert_equal @campaign.id, json_response["id"]
  end

  test "should create campaign" do
    assert_difference('Campaign.count') do
      post api_v1_campaigns_url,
           params: { campaign: {
             name: "New Campaign",
             subject: "New Subject",
             email_template_id: @email_template.id,
             contact_list_id: @contact_list.id,
             user_id: @user.id
           } },
           headers: @auth_headers, as: :json
    end
    assert_response :created
    assert_equal "draft", json_response["status"]
  end

  test "should create scheduled campaign" do
    assert_difference('Campaign.count') do
      post api_v1_campaigns_url,
           params: { campaign: {
             name: "Scheduled Campaign",
             subject: "Scheduled Subject",
             email_template_id: @email_template.id,
             contact_list_id: @contact_list.id,
             user_id: @user.id,
             scheduled_at: 1.day.from_now
           } },
           headers: @auth_headers, as: :json
    end
    assert_response :created
    assert_equal "draft", json_response["status"] # Should still be draft on creation
    assert_not_nil json_response["scheduled_at"]
  end


  test "should update campaign" do
    patch api_v1_campaign_url(@campaign),
          params: { campaign: { name: "Updated Campaign Name" } },
          headers: @auth_headers, as: :json
    assert_response :success
    @campaign.reload
    assert_equal "Updated Campaign Name", @campaign.name
  end

  test "should update campaign to scheduled" do
    patch api_v1_campaign_url(@campaign),
          params: { campaign: { scheduled_at: 2.days.from_now } },
          headers: @auth_headers, as: :json
    assert_response :success
    @campaign.reload
    assert_not_nil @campaign.scheduled_at
  end

  test "should destroy campaign" do
    assert_difference('Campaign.count', -1) do
      delete api_v1_campaign_url(@campaign), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end

  test "should send campaign immediately" do
    campaign = campaigns(:draft) # Assuming a draft campaign fixture
    post send_api_v1_campaign_url(campaign), headers: @auth_headers, as: :json
    assert_response :accepted
    assert_equal "Campaign queued for immediate sending", json_response["message"]
    assert_equal "sending", campaign.reload.status
  end

  test "should schedule campaign" do
    campaign = campaigns(:draft) # Assuming a draft campaign fixture
    post send_api_v1_campaign_url(campaign),
         params: { scheduled_at: 1.day.from_now },
         headers: @auth_headers, as: :json
    assert_response :accepted
    assert_equal "Campaign scheduled for delivery", json_response["message"]
    assert_equal "scheduled", campaign.reload.status
    assert_not_nil campaign.scheduled_at
  end

  test "should not send campaign if not draft" do
    campaign = campaigns(:sent) # Assuming a sent campaign fixture
    post send_api_v1_campaign_url(campaign), headers: @auth_headers, as: :json
    assert_response :unprocessable_entity
    assert_equal "Campaign must be in draft status to be sent or scheduled", json_response["message"]
  end

  test "should not schedule campaign with past scheduled_at" do
    campaign = campaigns(:draft)
    post send_api_v1_campaign_url(campaign),
         params: { scheduled_at: 1.day.ago },
         headers: @auth_headers, as: :json
    assert_response :unprocessable_entity # Change from internal_server_error
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
