require "test_helper"

class MangasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @manga = mangas(:one)
    @headers = {
      "X-API-KEY" => ENV.fetch("API_KEY")
    }
  end

  test "should get index" do
    get mangas_url

    assert_response :success
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
end