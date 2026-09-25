class MangaSerializer < ActiveModel::Serializer
  attributes :id, :title, :author, :synopsis, :chapter_count, :is_completed,
             :rating, :popularity, :release_year, :country_of_origin,
             :cover_image_url, :created_at, :updated_at

  has_many :genres
end
