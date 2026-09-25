class ReadingList < ApplicationRecord
  belongs_to :user
  belongs_to :manga

  # Scopes
  # Filter berdasarkan user
  scope :by_user, ->(user_id) { where(user_id: user_id) if user_id.present? }

  # Filter berdasarkan manga
  scope :by_manga, ->(manga_id) { where(manga_id: manga_id) if manga_id.present? }

  # Filter berdasarkan status (misal: reading, completed, plan_to_read)
  scope :by_status, ->(status) { where(status: status) if status.present? }
end
