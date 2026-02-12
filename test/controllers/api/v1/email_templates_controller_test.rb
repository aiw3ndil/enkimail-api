require "test_helper"

class Api::V1::EmailTemplatesControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    @user = users(:one)
    @auth_headers = { "Authorization" => "Bearer " + @user.api_key }
    @email_template = email_templates(:one) # Assuming an email_template fixture exists
  end

  test "should get index" do
    get api_v1_email_templates_url, headers: @auth_headers, as: :json
    assert_response :success
    assert_equal EmailTemplate.count, json_response.count
  end

  test "should show email_template" do
    get api_v1_email_template_url(@email_template), headers: @auth_headers, as: :json
    assert_response :success
    assert_equal @email_template.id, json_response["id"]
  end

  test "should create email_template" do
    assert_difference('EmailTemplate.count') do
      post api_v1_email_templates_url,
           params: { email_template: {
             name: "New Template #{SecureRandom.hex(4)}",
             subject: "New Subject",
             body: "New Body",
             user_id: @user.id
           } },
           headers: @auth_headers, as: :json
    end
    assert_response :created
  end

  test "should update email_template" do
    patch api_v1_email_template_url(@email_template),
          params: { email_template: { subject: "Updated Subject" } },
          headers: @auth_headers, as: :json
    assert_response :success
    @email_template.reload
    assert_equal "Updated Subject", @email_template.subject
  end

  test "should destroy email_template" do
    assert_difference('EmailTemplate.count', -1) do
      delete api_v1_email_template_url(@email_template), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
