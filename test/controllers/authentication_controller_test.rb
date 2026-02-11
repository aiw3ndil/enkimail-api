require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  test "should register user with valid params" do
    assert_difference('User.count') do
      post api_v1_register_path, params: { email: "test@example.com", password: "password", password_confirmation: "password" }
    end
    assert_response :created
    assert_not_nil json_response['api_key']
    assert_equal "test@example.com", json_response['email']
  end

  test "should not register user with invalid params" do
    post api_v1_register_path, params: { email: "invalid", password: "password", password_confirmation: "password" }
    assert_response :unprocessable_entity
    assert_not_nil json_response['email']
  end

  test "should not register user with mismatched passwords" do
    post api_v1_register_path, params: { email: "test2@example.com", password: "password", password_confirmation: "wrong" }
    assert_response :unprocessable_entity
    assert_not_nil json_response['password_confirmation']
  end

  test "should login user with valid credentials" do
    user = User.create!(email: "login@example.com", password: "password", password_confirmation: "password")
    post api_v1_login_path, params: { email: "login@example.com", password: "password" }
    assert_response :ok
    assert_equal user.api_key, json_response['api_key']
    assert_equal user.email, json_response['email']
  end

  test "should not login user with invalid credentials" do
    post api_v1_login_path, params: { email: "nonexistent@example.com", password: "password" }
    assert_response :unauthorized

    user = User.create!(email: "wrongpass@example.com", password: "password", password_confirmation: "password")
    post api_v1_login_path, params: { email: "wrongpass@example.com", password: "wrong_password" }
    assert_response :unauthorized
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
