require "test_helper"

class Api::V1::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = { "Authorization" => "Bearer #{@user.api_key}" }
    
    # Setup data
    @contact_list = contact_lists(:one)
    @contact_list.update(user: @user)
    
    @template = email_templates(:one)
    @template.update(user: @user)

    @campaign = campaigns(:sent)
    @campaign.update(user: @user, contact_list: @contact_list, email_template: @template)
    
    @contact = contacts(:one)
    @contact.update(user: @user)
    
    # Clear existing events to have a clean slate for stats
    EmailEvent.delete_all
  end

  test "should return correct dashboard stats" do
    # Create events
    # 10 Sent
    10.times do
      EmailEvent.create!(
        contact: @contact,
        campaign: @campaign,
        email_template: @template,
        event_type: :sent
      )
    end

    # 5 Opens
    5.times do
      EmailEvent.create!(
        contact: @contact,
        campaign: @campaign,
        email_template: @template,
        event_type: :open
      )
    end

    # 2 Clicks
    2.times do
      EmailEvent.create!(
        contact: @contact,
        campaign: @campaign,
        email_template: @template,
        event_type: :click,
        url: "http://example.com"
      )
    end

    # 1 Bounce
    EmailEvent.create!(
      contact: @contact,
      campaign: @campaign,
      email_template: @template,
      event_type: :bounce
    )

    get api_v1_dashboard_url, headers: @headers
    assert_response :success
    
    json_response = JSON.parse(response.body)
    
    assert_equal 10, json_response["total_sent"]
    assert_equal 5, json_response["events"]["opens"]
    assert_equal 2, json_response["events"]["clicks"]
    assert_equal 1, json_response["events"]["bounces"]
    
    # Check rates
    # Open rate: 5/10 = 50.0%
    assert_equal 50.0, json_response["rates"]["open_rate"]
    
    # Click rate: 2/10 = 20.0%
    assert_equal 20.0, json_response["rates"]["click_rate"]
    
    # Bounce rate: 1/10 = 10.0%
    assert_equal 10.0, json_response["rates"]["bounce_rate"]
  end
end
