require "test_helper"

class BestMangasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @best_manga = best_mangas(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get best_mangas_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get best_mangas_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get best_mangas_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by manga_id" do
    get best_mangas_url, params: { manga_id: @best_manga.manga_id }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |bm|
      assert_equal @best_manga.manga_id, bm["manga_id"]
    end
  end

  test "index should filter by min_rank" do
    get best_mangas_url, params: { min_rank: 1 }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |bm|
      assert bm["rank"] >= 1
    end
  end

  test "index should filter by max_rank" do
    get best_mangas_url, params: { max_rank: 10 }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |bm|
      assert bm["rank"] <= 10
    end
  end

  test "should create best_manga" do
    manga = Manga.create!(
      title: "Manga For Best Test",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapter_count: 10,
      is_completed: false
    )

    assert_difference("BestManga.count", 1) do
      post best_mangas_url,
        params: {
          best_manga: {
            manga_id: manga.id,
            rank: 3,
            score: 8.5,
            reason: "Test reason"
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show best_manga" do
    get best_manga_url(@best_manga)

    assert_response :success
  end

  test "should update best_manga" do
    patch best_manga_url(@best_manga),
      params: {
        best_manga: {
          manga_id: @best_manga.manga_id,
          rank: @best_manga.rank,
          score: @best_manga.score,
          reason: "Updated reason"
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy best_manga" do
    assert_difference("BestManga.count", -1) do
      delete best_manga_url(@best_manga),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when best_manga not found" do
    get best_manga_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 422 when best_manga creation validation fails" do
    post best_mangas_url,
      params: {
        best_manga: {
          rank: 999 # invalid rank (> 10)
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 422 when best_manga update validation fails" do
    patch best_manga_url(@best_manga),
      params: {
        best_manga: {
          rank: 999
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 400 when required best_manga parameter is missing" do
    post best_mangas_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end
end
