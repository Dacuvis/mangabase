require "test_helper"

class BestMangasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @best_manga = best_mangas(:one)
  end

  test "should get index" do
    get best_mangas_url, as: :json
    assert_response :success
  end

  test "should create best_manga" do
    assert_difference("BestManga.count") do
      post best_mangas_url, params: { best_manga: { manga_id: @best_manga.manga_id, rank: @best_manga.rank, reason: @best_manga.reason, score: @best_manga.score } }, as: :json
    end

    assert_response :created
  end

  test "should show best_manga" do
    get best_manga_url(@best_manga), as: :json
    assert_response :success
  end

  test "should update best_manga" do
    patch best_manga_url(@best_manga), params: { best_manga: { manga_id: @best_manga.manga_id, rank: @best_manga.rank, reason: @best_manga.reason, score: @best_manga.score } }, as: :json
    assert_response :success
  end

  test "should destroy best_manga" do
    assert_difference("BestManga.count", -1) do
      delete best_manga_url(@best_manga), as: :json
    end

    assert_response :no_content
  end
end
