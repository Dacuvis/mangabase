require "test_helper"

class GenresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genre = genres(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY", "jUSTIN")
    }
  end

  test "should get index" do
    get genres_url

    assert_response :success
  end

  test "index should return paginated response with meta" do
    get genres_url

    json_response = response.parsed_body
    assert json_response.key?("data")
    assert json_response.key?("meta")
    assert json_response.dig("meta", "current_page")
    assert json_response.dig("meta", "per_page")
    assert json_response.dig("meta", "total_count")
    assert json_response.dig("meta", "total_pages")
  end

  test "index should respect page and per_page params" do
    get genres_url, params: { page: 1, per_page: 1 }

    assert_response :success
    json_response = response.parsed_body
    assert_equal 1, json_response.dig("meta", "current_page")
    assert_equal 1, json_response.dig("meta", "per_page")
    assert json_response["data"].length <= 1
  end

  test "index should filter by search query" do
    get genres_url, params: { q: @genre.name }

    assert_response :success
    json_response = response.parsed_body
    assert json_response["data"].any? { |g| g["name"] == @genre.name }
  end

  test "should create genre" do
    assert_difference("Genre.count", 1) do
      post genres_url,
        params: {
          genre: {
            name: "Horror",
            slug: "horror"
          }
        },
        headers: @headers
    end

    assert_response :created
  end

  test "should show genre" do
    get genre_url(@genre)

    assert_response :success
  end

  test "should update genre" do
    patch genre_url(@genre),
      params: {
        genre: {
          name: "Action Updated",
          slug: @genre.slug
        }
      },
      headers: @headers

    assert_response :success
  end

  test "should destroy genre" do
    genre = Genre.create!(name: "To Delete", slug: "to-delete")

    assert_difference("Genre.count", -1) do
      delete genre_url(genre),
        headers: @headers
    end

    assert_response :no_content
  end

  test "should return 404 when genre not found" do
    get genre_url(id: 999_999)

    assert_response :not_found
    json_response = response.parsed_body
    assert_equal "NOT_FOUND", json_response.dig("error", "code")
  end

  test "should return 422 when genre creation validation fails" do
    post genres_url,
      params: {
        genre: {
          name: "",
          slug: "INVALID SLUG!"
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
    assert_not_empty json_response.dig("error", "details")
  end

  test "should return 422 when genre update validation fails" do
    patch genre_url(@genre),
      params: {
        genre: {
          name: ""
        }
      },
      headers: @headers

    assert_response :unprocessable_entity
    json_response = response.parsed_body
    assert_equal "VALIDATION_ERROR", json_response.dig("error", "code")
  end

  test "should return 400 when required genre parameter is missing" do
    post genres_url,
      params: {},
      headers: @headers

    assert_response :bad_request
    json_response = response.parsed_body
    assert_equal "BAD_REQUEST", json_response.dig("error", "code")
  end

  test "should return 401 when api key is missing on create" do
    post genres_url,
      params: {
        genre: {
          name: "Sci-Fi",
          slug: "sci-fi"
        }
      }

    assert_response :unauthorized
  end
end
