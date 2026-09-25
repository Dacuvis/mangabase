class UnderratedMangaSerializer < ActiveModel::Serializer
  attributes :id, :score, :reason, :manga_id

  belongs_to :manga
end
