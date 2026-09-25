class Genre < ApplicationRecord
  has_many :manga_genres, dependent: :destroy
  has_many :mangas, through: :manga_genres

  validates :name, presence: { message: "wajib diisi" },
                   length: { maximum: 255 },
                   uniqueness: { message: "sudah ada" }

  validates :slug, presence: { message: "wajib diisi" },
                   length: { maximum: 255 },
                   uniqueness: { message: "sudah digunakan" },
                   format: { with: /\A[a-z0-9-]+\z/, message: "hanya boleh huruf kecil, angka, dan tanda hubung" }

  # Scopes
  # Cari berdasarkan name atau slug (case-insensitive)
  scope :search, ->(query) {
    where("name LIKE :q OR slug LIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }
end
