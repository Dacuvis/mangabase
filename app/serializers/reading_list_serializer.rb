class ReadingListSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :manga_id, :status, :progress_chapter, :created_at, :updated_at
end
