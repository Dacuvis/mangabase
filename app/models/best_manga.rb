class BestManga < ApplicationRecord
  belongs_to :manga

  validates :rank, presence: true,
                   numericality: { only_integer: true, in: 1..10 },
                   uniqueness: { message: "sudah terisi manga lain" }

  validates :manga_id, uniqueness: { message: "sudah ada dalam daftar Best Manga" }

  validate :max_ten_entries, on: :create

  # Scopes
  # Filter berdasarkan manga
  scope :by_manga, ->(manga_id) { where(manga_id: manga_id) if manga_id.present? }

  # Filter berdasarkan rank minimum
  scope :min_rank, ->(val) { where("`rank` >= ?", val.to_i) if val.present? }

  # Filter berdasarkan rank maksimum
  scope :max_rank, ->(val) { where("`rank` <= ?", val.to_i) if val.present? }

  # Filter berdasarkan score minimum
  scope :min_score, ->(score) { where("score >= ?", score.to_f) if score.present? }

  # Filter berdasarkan score maksimum
  scope :max_score, ->(score) { where("score <= ?", score.to_f) if score.present? }

  private

  def max_ten_entries
    if BestManga.count >= 10
      errors.add(:base, "Daftar Best Manga sudah penuh")
    end
  end
end
