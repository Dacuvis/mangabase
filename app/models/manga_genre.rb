class MangaGenre < ApplicationRecord
  belongs_to :manga
  belongs_to :genre

  validates :manga_id, uniqueness: { scope: :genre_id, message: "sudah terhubung dengan genre ini" }

  # Scopes
  # Filter berdasarkan manga
  scope :by_manga, ->(manga_id) { where(manga_id: manga_id) if manga_id.present? }

  # Filter berdasarkan genre
  scope :by_genre, ->(genre_id) { where(genre_id: genre_id) if genre_id.present? }
end
