require "test_helper"

class ReadingListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @reading_list = reading_lists(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get reading_lists_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get reading_lists_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get reading_lists_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by user_id" do
    get reading_lists_url, params: { user_id: @reading_list.user_id }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |rl|
      assert_equal @reading_list.user_id, rl["user_id"]
    end
  end

  test "index should filter by manga_id" do
    get reading_lists_url, params: { manga_id: @reading_list.manga_id }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |rl|
      assert_equal @reading_list.manga_id, rl["manga_id"]
    end
  end

  test "index should filter by status" do
    get reading_lists_url, params: { status: @reading_list.status }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |rl|
      assert_equal @reading_list.status, rl["status"]
    end
  end

  test "should create reading_list" do
    user = User.create!(name: "New User", email: "newuser@example.com")
    manga = Manga.create!(
      title: "Manga For Reading List",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapet_count: 10,
      is_completed: false
    )

    assert_difference("ReadingList.count", 1) do
      post reading_lists_url,
        params: {
          reading_list: {
            user_id: user.id,
            manga_id: manga.id,
            status: "reading",
            progress_chapter: 5
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show reading_list" do
    get reading_list_url(@reading_list)

    assert_response :success
  end

  test "should update reading_list" do
    patch reading_list_url(@reading_list),
      params: {
        reading_list: {
          user_id: @reading_list.user_id,
          manga_id: @reading_list.manga_id,
          status: "completed",
          progress_chapter: 100
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy reading_list" do
    user = User.create!(name: "Delete User", email: "deleteuser@example.com")
    manga = Manga.create!(
      title: "Manga To Delete",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapet_count: 5,
      is_completed: false
    )
    reading_list = ReadingList.create!(
      user: user,
      manga: manga,
      status: "plan_to_read",
      progress_chapter: 0
    )

    assert_difference("ReadingList.count", -1) do
      delete reading_list_url(reading_list),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when reading_list not found" do
    get reading_list_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 400 when required reading_list parameter is missing" do
    post reading_lists_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end

  test "should return 401 when api key is missing on create" do
    post reading_lists_url,
      params: {
        reading_list: {
          user_id: @reading_list.user_id,
          manga_id: @reading_list.manga_id,
          status: "reading",
          progress_chapter: 1
        }
      }

    assert_response :unauthorized
  end
end
