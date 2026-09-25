class MangaGenreSerializer < ActiveModel::Serializer
  attributes :id, :manga_id, :genre_id

  belongs_to :manga
  belongs_to :genre
end
