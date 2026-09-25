class User < ApplicationRecord
  has_many :reading_lists, dependent: :destroy

  validates :name, presence: { message: "wajib diisi" },
                   length: { maximum: 255 }

  validates :email, presence: { message: "wajib diisi" },
                    length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "tidak valid" },
                    uniqueness: { message: "sudah digunakan" }

  # Scopes
  # Cari berdasarkan name atau email (case-insensitive)
  scope :search, ->(query) {
    where("name LIKE :q OR email LIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }
end
