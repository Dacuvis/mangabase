require "test_helper"

class UnderratedMangasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @underrated_manga = underrated_mangas(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get underrated_mangas_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get underrated_mangas_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get underrated_mangas_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by manga_id" do
    get underrated_mangas_url, params: { manga_id: @underrated_manga.manga_id }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |um|
      assert_equal @underrated_manga.manga_id, um["manga_id"]
    end
  end

  test "index should filter by min_score" do
    get underrated_mangas_url, params: { min_score: 9.0 }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |um|
      assert um["score"].to_f >= 9.0
    end
  end

  test "should create underrated_manga" do
    manga = Manga.create!(
      title: "Manga For Underrated Test",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapet_count: 10,
      is_completed: false
    )

    assert_difference("UnderratedManga.count") do
      post underrated_mangas_url,
        params: {
          underrated_manga: {
            manga_id: manga.id,
            rank: 3,
            reason: "A hidden gem",
            score: 8.5
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show underrated_manga" do
    get underrated_manga_url(@underrated_manga)

    assert_response :success
  end

  test "should update underrated_manga" do
    patch underrated_manga_url(@underrated_manga),
      params: {
        underrated_manga: {
          reason: "Updated reason"
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy underrated_manga" do
    assert_difference("UnderratedManga.count", -1) do
      delete underrated_manga_url(@underrated_manga),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when underrated_manga not found" do
    get underrated_manga_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 422 when underrated_manga creation validation fails" do
    post underrated_mangas_url,
      params: {
        underrated_manga: {
          manga_id: nil,
          reason: ""
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 422 when underrated_manga update validation fails" do
    patch underrated_manga_url(@underrated_manga),
      params: {
        underrated_manga: {
          reason: ""
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 400 when required underrated_manga parameter is missing" do
    post underrated_mangas_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end

  test "should return 401 when api key is missing on create" do
    post underrated_mangas_url,
      params: {
        underrated_manga: {
          manga_id: mangas(:one).id,
          reason: "Test"
        }
      }

    assert_response :unauthorized
  end
end
