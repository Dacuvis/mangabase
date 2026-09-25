class BestMangaSerializer < ActiveModel::Serializer
  attributes :id, :rank, :score, :reason, :manga_id

  belongs_to :manga
end
