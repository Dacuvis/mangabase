class FixDbIntegrityAndAddFeatures < ActiveRecord::Migration[8.1]
  def up
    # -------------------------------------------------------------------------
    # mangas: NOT NULL, rename chapet_count → chapter_count, fulltext index
    # -------------------------------------------------------------------------
    change_column_null :mangas, :title, false
    change_column_default :mangas, :is_completed, false
    change_column_null :mangas, :is_completed, false

    # Rename hanya jika kolom lama masih ada
    if column_exists?(:mangas, :chapet_count)
      rename_column :mangas, :chapet_count, :chapter_count
    end

    # FULLTEXT index untuk pencarian title & author (MySQL)
    unless index_exists?(:mangas, %i[ title author ], name: "mangas_fulltext_title_author")
      execute "ALTER TABLE mangas ADD FULLTEXT INDEX mangas_fulltext_title_author (title, author)"
    end

    # -------------------------------------------------------------------------
    # genres: NOT NULL + unique indexes
    # -------------------------------------------------------------------------
    change_column_null :genres, :name, false
    change_column_null :genres, :slug, false
    add_index :genres, :name, unique: true unless index_exists?(:genres, :name)
    add_index :genres, :slug, unique: true unless index_exists?(:genres, :slug)

    # -------------------------------------------------------------------------
    # users: NOT NULL + unique index email
    # -------------------------------------------------------------------------
    change_column_null :users, :name, false
    change_column_null :users, :email, false
    add_index :users, :email, unique: true unless index_exists?(:users, :email)

    # -------------------------------------------------------------------------
    # manga_genres: composite unique index (manga_id, genre_id)
    # -------------------------------------------------------------------------
    unless index_exists?(:manga_genres, %i[ manga_id genre_id ], name: "index_manga_genres_on_manga_id_and_genre_id")
      add_index :manga_genres, [ :manga_id, :genre_id ], unique: true
    end

    # -------------------------------------------------------------------------
    # reading_lists: enum status (0=plan_to_read, 1=reading, 2=completed, 3=dropped)
    # -------------------------------------------------------------------------
    change_column :reading_lists, :status, :integer, default: 0, null: false,
                  comment: "0=plan_to_read 1=reading 2=completed 3=dropped"

    # -------------------------------------------------------------------------
    # best_mangas: jadikan index manga_id unique
    # MySQL tidak bisa drop index yang dipakai FK — drop FK dulu, lalu recreate
    # -------------------------------------------------------------------------
    existing = connection.indexes(:best_mangas).find { |i| i.columns == [ "manga_id" ] }
    if existing && !existing.unique
      remove_foreign_key :best_mangas, :mangas
      remove_index :best_mangas, :manga_id
      add_index :best_mangas, :manga_id, unique: true
      add_foreign_key :best_mangas, :mangas
    elsif !existing
      add_index :best_mangas, :manga_id, unique: true
    end

    # -------------------------------------------------------------------------
    # underrated_mangas: jadikan index manga_id unique
    # -------------------------------------------------------------------------
    existing = connection.indexes(:underrated_mangas).find { |i| i.columns == [ "manga_id" ] }
    if existing && !existing.unique
      remove_foreign_key :underrated_mangas, :mangas
      remove_index :underrated_mangas, :manga_id
      add_index :underrated_mangas, :manga_id, unique: true
      add_foreign_key :underrated_mangas, :mangas
    elsif !existing
      add_index :underrated_mangas, :manga_id, unique: true
    end
  end

  def down
    existing = connection.indexes(:underrated_mangas).find { |i| i.columns == [ "manga_id" ] }
    if existing&.unique
      remove_foreign_key :underrated_mangas, :mangas
      remove_index :underrated_mangas, :manga_id
      add_index :underrated_mangas, :manga_id
      add_foreign_key :underrated_mangas, :mangas
    end

    existing = connection.indexes(:best_mangas).find { |i| i.columns == [ "manga_id" ] }
    if existing&.unique
      remove_foreign_key :best_mangas, :mangas
      remove_index :best_mangas, :manga_id
      add_index :best_mangas, :manga_id
      add_foreign_key :best_mangas, :mangas
    end

    change_column :reading_lists, :status, :string

    if index_exists?(:manga_genres, %i[ manga_id genre_id ], name: "index_manga_genres_on_manga_id_and_genre_id")
      remove_index :manga_genres, [ :manga_id, :genre_id ]
    end

    remove_index :users, :email if index_exists?(:users, :email)
    change_column_null :users, :email, true
    change_column_null :users, :name, true

    remove_index :genres, :slug if index_exists?(:genres, :slug)
    remove_index :genres, :name if index_exists?(:genres, :name)
    change_column_null :genres, :slug, true
    change_column_null :genres, :name, true

    execute "ALTER TABLE mangas DROP INDEX mangas_fulltext_title_author" if index_exists?(:mangas, %i[ title author ], name: "mangas_fulltext_title_author")

    if column_exists?(:mangas, :chapter_count)
      rename_column :mangas, :chapter_count, :chapet_count
    end

    change_column_null :mangas, :is_completed, true
    change_column_default :mangas, :is_completed, nil
    change_column_null :mangas, :title, true
  end
end
