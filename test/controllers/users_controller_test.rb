require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get users_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get users_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get users_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by search query on name" do
    get users_url, params: { q: @user.name }

    assert_response :success
    json_response = response.parsed_body
    assert json_response["data"].any? { |u| u["name"] == @user.name }
  end

  test "index should filter by search query on email" do
    get users_url, params: { q: @user.email }

    assert_response :success
    json_response = response.parsed_body
    assert json_response["data"].any? { |u| u["email"] == @user.email }
  end

  test "should create user" do
    assert_difference("User.count", 1) do
      post users_url,
        params: {
          user: {
            name: "Charlie",
            email: "charlie@example.com"
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show user" do
    get user_url(@user)

    assert_response :success
  end

  test "should update user" do
    patch user_url(@user),
      params: {
        user: {
          name: "Alice Updated",
          email: @user.email
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy user" do
    user = User.create!(name: "Delete Me", email: "delete@example.com")

    assert_difference("User.count", -1) do
      delete user_url(user),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when user not found" do
    get user_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 422 when user creation validation fails" do
    post users_url,
      params: {
        user: {
          name: "",
          email: "not-an-email"
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
    assert_not_empty json_response.dig("error", "details")
  end

  test "should return 422 when user update validation fails" do
    patch user_url(@user),
      params: {
        user: {
          email: "invalid-email"
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 400 when required user parameter is missing" do
    post users_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end

  test "should return 401 when api key is missing on create" do
    post users_url,
      params: {
        user: {
          name: "Unauthorized",
          email: "unauth@example.com"
        }
      }

    assert_response :unauthorized
  end
end
