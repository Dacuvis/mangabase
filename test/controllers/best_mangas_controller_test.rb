require "test_helper"

class BestMangasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @best_manga = best_mangas(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY")
    }
  end

  test "should get index" do
    get best_mangas_url

    assert_response :success
  end

  test "should create best_manga" do
    manga = Manga.create!(
      title: "Manga For Best Test",
      author: "Test Author",
      synopsis: "Test synopsis",
      chapet_count: 10,
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
end
