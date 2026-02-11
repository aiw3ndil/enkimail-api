require "test_helper"

class TrackingControllerTest < ActionDispatch::IntegrationTest
  test "should get open" do
    get tracking_open_url
    assert_response :success
  end

  test "should get click" do
    get tracking_click_url
    assert_response :success
  end
end
