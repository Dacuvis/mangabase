class UnderratedManga < ApplicationRecord
  belongs_to :manga

  validates :manga_id, presence: true, uniqueness: true
  validates :reason, presence: true

  # Scopes
  # Filter berdasarkan manga
  scope :by_manga, ->(manga_id) { where(manga_id: manga_id) if manga_id.present? }

  # Filter berdasarkan score minimum
  scope :min_score, ->(score) { where("score >= ?", score.to_f) if score.present? }

  # Filter berdasarkan score maksimum
  scope :max_score, ->(score) { where("score <= ?", score.to_f) if score.present? }
end
