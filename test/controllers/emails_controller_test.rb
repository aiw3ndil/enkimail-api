require "test_helper"

class EmailsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get emails_create_url
    assert_response :success
  end
end
