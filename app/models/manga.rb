class Manga < ApplicationRecord
  has_one :best_manga, dependent: :destroy
  has_one :underrated_manga, dependent: :destroy
  has_many :manga_genres, dependent: :destroy
  has_many :genres, through: :manga_genres
  has_many :reading_lists, dependent: :destroy

  # 1. Title: Wajib diisi & maksimal 255 karakter
  validates :title, presence: { message: "wajib diisi" },
                    length: { maximum: 255 }

  # 2. Author: Maksimal 255 karakter (otomatis mengizinkan nilai kosong/nil jika tidak ada 'presence: true')
  validates :author, length: { maximum: 255 }, allow_nil: true

  # 3. Chapet Count: Harus berupa angka integer >= 0 jika diisi
  validates :chapet_count, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, allow_nil: true

  # 4. Is Completed: Harus boolean jika diisi
  validates :is_completed, inclusion: { in: [ true, false ] }, allow_nil: true

  # Catatan: Kolom 'synopsis' tidak perlu baris 'validates' karena bersifat bebas/opsional.

  # Scopes
  # Cari berdasarkan title atau author (case-insensitive)
  scope :search, ->(query) {
    where("title LIKE :q OR author LIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }

  # Filter berdasarkan status completed (true/false)
  scope :by_completed, ->(status) {
    where(is_completed: ActiveModel::Type::Boolean.new.cast(status)) unless status.nil?
  }

  # Filter berdasarkan genre
  scope :by_genre, ->(genre_id) {
    joins(:manga_genres).where(manga_genres: { genre_id: genre_id }) if genre_id.present?
  }
end
