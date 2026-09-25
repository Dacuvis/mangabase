require "test_helper"

class MangasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manga = mangas(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get mangas_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get mangas_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get mangas_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by search query" do
    get mangas_url, params: { q: @manga.title }

    assert_response :success
    json_response = response.parsed_body
    assert json_response["data"].any? { |m| m["title"] == @manga.title }
  end

  test "index should filter by is_completed" do
    get mangas_url, params: { is_completed: false }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |m|
      assert_equal false, m["is_completed"]
    end
  end

  test "index should filter by genre_id" do
    # manga_genres(:one) sudah menghubungkan mangas(:one) dengan genres(:one) via fixture
    genre = genres(:one)

    get mangas_url, params: { genre_id: genre.id }

    assert_response :success
    json_response = response.parsed_body
    assert json_response["data"].any? { |m| m["id"] == @manga.id }
  end

  test "should create manga" do
    assert_difference("Manga.count", 1) do
      post mangas_url,
        params: {
          manga: {
            title: "Test Manga",
            author: "Test Author",
            synopsis: "Test synopsis",
            chapet_count: 10,
            is_completed: false
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show manga" do
    get manga_url(@manga)

    assert_response :success
  end

  test "should update manga" do
    patch manga_url(@manga),
      params: {
        manga: {
          title: "Updated Manga",
          author: "Updated Author",
          synopsis: "Updated synopsis",
          chapet_count: 20,
          is_completed: true
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy manga" do
    manga = Manga.create!(
      title: "Manga to Delete",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapet_count: 10,
      is_completed: false
    )

    assert_difference("Manga.count", -1) do
      delete manga_url(manga),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when manga not found" do
    get manga_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 422 when manga creation validation fails" do
    post mangas_url,
      params: {
        manga: {
          title: ""
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
    assert_includes json_response.dig("error", "details"), "Title wajib diisi"
  end

  test "should return 422 when manga update validation fails" do
    patch manga_url(@manga),
      params: {
        manga: {
          title: ""
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 400 when required manga parameter is missing" do
    post mangas_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end
end
