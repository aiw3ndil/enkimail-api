require "test_helper"

class Api::V1::ContactListsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    @user = users(:one)
    @auth_headers = { "Authorization" => "Bearer " + @user.api_key }
    @contact_list = contact_lists(:one) # Assuming a contact_list fixture exists
    @contact = contacts(:one) # Assuming a contact fixture exists
  end

  test "should get index" do
    get api_v1_contact_lists_url, headers: @auth_headers, as: :json
    assert_response :success
    assert_equal ContactList.count, json_response.count
  end

  test "should show contact_list" do
    get api_v1_contact_list_url(@contact_list), headers: @auth_headers, as: :json
    assert_response :success
    assert_equal @contact_list.id, json_response["id"]
  end

  test "should create contact_list" do
    assert_difference('ContactList.count') do
      post api_v1_contact_lists_url,
           params: { contact_list: {
             name: "New Contact List #{SecureRandom.hex(4)}",
             description: "A new list",
             user_id: @user.id
           } },
           headers: @auth_headers, as: :json
    end
    assert_response :created
  end

  test "should update contact_list" do
    patch api_v1_contact_list_url(@contact_list),
          params: { contact_list: { name: "Updated List Name" } },
          headers: @auth_headers, as: :json
    assert_response :success
    @contact_list.reload
    assert_equal "Updated List Name", @contact_list.name
  end

  test "should destroy contact_list" do
    assert_difference('ContactList.count', -1) do
      delete api_v1_contact_list_url(@contact_list), headers: @auth_headers, as: :json
    end
    assert_response :no_content
  end

  test "should add contact to list" do
    # Create a contact that is not yet in @contact_list
    contact_to_add = Contact.create!(email: "add_me_#{SecureRandom.hex(4)}@example.com", user: @user, status: :subscribed)

    assert_difference('@contact_list.contacts.count', 1) do
      post add_contact_api_v1_contact_list_url(@contact_list),
           params: { contact_id: contact_to_add.id },
           headers: @auth_headers, as: :json
    end
    assert_response :ok
    assert json_response.any? { |c| c["id"] == contact_to_add.id }
  end

  test "should remove contact from list" do
    # Ensure contact is in the list first
    contact_to_remove = Contact.create!(email: "remove_me_#{SecureRandom.hex(4)}@example.com", user: @user, status: :subscribed)
    @contact_list.contacts << contact_to_remove

    assert_difference('@contact_list.contacts.count', -1) do
      delete remove_contact_api_v1_contact_list_url(@contact_list),
             params: { contact_id: contact_to_remove.id },
             headers: @auth_headers, as: :json
    end
    assert_response :ok
    assert_not json_response.any? { |c| c["id"] == contact_to_remove.id }
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
