require "test_helper"

class Api::V1::ContactsReproductionTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @auth_headers_one = { "Authorization" => "Bearer " + @user_one.api_key }
    @auth_headers_two = { "Authorization" => "Bearer " + @user_two.api_key }
  end

  test "should allow creating contact with same email for different users" do
    email = "test_duplicate@example.com"

    # User One creates contact
    post api_v1_contacts_url,
         params: { contact: { email: email, first_name: "John", last_name: "Doe", status: "subscribed" } },
         headers: @auth_headers_one, as: :json
    assert_response :created

    # User Two creates contact with same email
    post api_v1_contacts_url,
         params: { contact: { email: email, first_name: "Jane", last_name: "Doe", status: "subscribed" } },
         headers: @auth_headers_two, as: :json
    assert_response :created
  end

  test "should not allow creating contact with same email for same user" do
    email = "test_unique@example.com"

    # User One creates contact
    post api_v1_contacts_url,
         params: { contact: { email: email, first_name: "John", last_name: "Doe", status: "subscribed" } },
         headers: @auth_headers_one, as: :json
    assert_response :created

    # User One tries to create same contact again
    post api_v1_contacts_url,
         params: { contact: { email: email, first_name: "John", last_name: "Doe", status: "subscribed" } },
         headers: @auth_headers_one, as: :json
    
    # Should be 422 if validation handles it, or 500 if DB error is unhandled
    if response.status == 500
      puts "Reproduced 500 error for duplicate contact on same user"
    end
    assert_response :unprocessable_entity
  end
end
