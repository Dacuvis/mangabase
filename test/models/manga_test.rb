require "test_helper"

class MangaTest < ActiveSupport::TestCase
  test "has_one best_manga relation and dependent destroy" do
    manga = Manga.create!(title: "Rel Manga 1")
    best = BestManga.create!(manga: manga, rank: 5, score: 9.0, reason: "Awesome")

    assert_equal best, manga.best_manga

    assert_difference("BestManga.count", -1) do
      manga.destroy!
    end
  end

  test "has_one underrated_manga relation and dependent destroy" do
    manga = Manga.create!(title: "Rel Manga 2")
    underrated = UnderratedManga.create!(manga: manga, rank: 1, score: 8.0, reason: "Underrated gem")

    assert_equal underrated, manga.underrated_manga

    assert_difference("UnderratedManga.count", -1) do
      manga.destroy!
    end
  end
end
