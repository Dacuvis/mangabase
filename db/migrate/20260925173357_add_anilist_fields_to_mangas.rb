class AddAnilistFieldsToMangas < ActiveRecord::Migration[8.1]
  def change
    # Hapus Active Storage cover_image (pakai URL string lebih simpel untuk import massal)
    # Active Storage attachment dihapus di model, tabel active_storage_* tetap ada

    add_column :mangas, :rating,            :decimal, precision: 4, scale: 2
    add_column :mangas, :popularity,        :integer
    add_column :mangas, :release_year,      :integer
    add_column :mangas, :country_of_origin, :string,  limit: 2
    add_column :mangas, :cover_image_url,   :string,  limit: 500
  end
end
