class Manga < ApplicationRecord
  has_one :best_manga, dependent: :destroy
  has_one :underrated_manga, dependent: :destroy
  has_many :manga_genres, dependent: :destroy
  has_many :genres, through: :manga_genres
  has_many :reading_lists, dependent: :destroy

  validates :title, presence: { message: "wajib diisi" },
                    length: { maximum: 255 }

  validates :author, length: { maximum: 255 }, allow_nil: true

  validates :chapter_count, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, allow_nil: true

  validates :is_completed, inclusion: { in: [ true, false ] }, allow_nil: true

  validates :rating, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 10
  }, allow_nil: true

  validates :popularity, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, allow_nil: true

  validates :release_year, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1900,
    less_than_or_equal_to: Date.current.year + 1
  }, allow_nil: true

  validates :country_of_origin, length: { is: 2 }, allow_nil: true

  validates :cover_image_url, length: { maximum: 500 }, allow_nil: true

  # Scopes
  scope :search, ->(query) {
    if query.present?
      where("MATCH(title, author) AGAINST(? IN BOOLEAN MODE)", "#{sanitize_sql_like(query)}*")
    end
  }

  scope :by_completed, ->(status) {
    where(is_completed: ActiveModel::Type::Boolean.new.cast(status)) unless status.nil?
  }

  scope :by_genre, ->(genre_id) {
    joins(:manga_genres).where(manga_genres: { genre_id: genre_id }) if genre_id.present?
  }
end
