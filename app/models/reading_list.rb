class ReadingList < ApplicationRecord
  belongs_to :user
  belongs_to :manga

  enum :status, {
    plan_to_read: 0,
    reading: 1,
    completed: 2,
    dropped: 3
  }

  validates :status, presence: true

  validates :progress_chapter, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, allow_nil: true

  # Scopes
  scope :by_user,   ->(user_id)  { where(user_id: user_id)   if user_id.present? }
  scope :by_manga,  ->(manga_id) { where(manga_id: manga_id) if manga_id.present? }
  scope :by_status, ->(status)   { where(status: status)     if status.present? }
end
