require "test_helper"

class Api::V1::GoogleLoginTest < ActionDispatch::IntegrationTest
  test "google_login returns 401 with invalid token" do
    post api_v1_google_login_path, params: { id_token: "invalid_token" }
    assert_response :unauthorized
    assert_match /Invalid Google token/, JSON.parse(response.body)['error']
  end

  test "google_login returns 401 without token" do
    post api_v1_google_login_path, params: {}
    assert_response :unauthorized
    assert_match /Invalid Google token/, JSON.parse(response.body)['error']
  end
end
