require "test_helper"

class MangaGenresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manga_genre = manga_genres(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get manga_genres_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get manga_genres_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get manga_genres_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by manga_id" do
    get manga_genres_url, params: { manga_id: @manga_genre.manga_id }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |mg|
      assert_equal @manga_genre.manga_id, mg["manga_id"]
    end
  end

  test "index should filter by genre_id" do
    get manga_genres_url, params: { genre_id: @manga_genre.genre_id }

    assert_response :success
    json_response = response.parsed_body
    json_response["data"].each do |mg|
      assert_equal @manga_genre.genre_id, mg["genre_id"]
    end
  end

  test "should create manga_genre" do
    manga = Manga.create!(
      title: "New Manga For Genre Test",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapter_count: 5,
      is_completed: false
    )
    genre = genres(:two)

    assert_difference("MangaGenre.count", 1) do
      post manga_genres_url,
        params: {
          manga_genre: {
            manga_id: manga.id,
            genre_id: genre.id
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show manga_genre" do
    get manga_genre_url(@manga_genre)

    assert_response :success
  end

  test "should update manga_genre" do
    manga = Manga.create!(
      title: "Another Manga",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapter_count: 5,
      is_completed: false
    )

    patch manga_genre_url(@manga_genre),
      params: {
        manga_genre: {
          manga_id: manga.id,
          genre_id: @manga_genre.genre_id
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy manga_genre" do
    manga_genre = MangaGenre.create!(
      manga: mangas(:one),
      genre: genres(:two)
    )

    assert_difference("MangaGenre.count", -1) do
      delete manga_genre_url(manga_genre),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when manga_genre not found" do
    get manga_genre_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 422 when manga_genre creation is duplicate" do
    post manga_genres_url,
      params: {
        manga_genre: {
          manga_id: @manga_genre.manga_id,
          genre_id: @manga_genre.genre_id
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 400 when required manga_genre parameter is missing" do
    post manga_genres_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end

  test "should return 401 when api key is missing on create" do
    post manga_genres_url,
      params: {
        manga_genre: {
          manga_id: mangas(:one).id,
          genre_id: genres(:one).id
        }
      }

    assert_response :unauthorized
  end
end
