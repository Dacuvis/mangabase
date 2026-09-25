require "csv"

namespace :export do
  desc "Export manga data ke CSV untuk Kaggle dataset. Usage: rails export:csv"
  task csv: :environment do
    output_dir = Rails.root.join("tmp", "exports")
    FileUtils.mkdir_p(output_dir)

    # -------------------------------------------------------------------------
    # mangas.csv
    # -------------------------------------------------------------------------
    mangas_path = output_dir.join("mangas.csv")
    print "Exporting mangas.csv ... "
    CSV.open(mangas_path, "w") do |csv|
      csv << %w[
        id title author synopsis chapter_count is_completed
        rating popularity release_year country_of_origin cover_image_url
        genres created_at
      ]

      Manga.includes(:genres).find_each do |manga|
        csv << [
          manga.id,
          manga.title,
          manga.author,
          manga.synopsis&.gsub(/\n/, " "),
          manga.chapter_count,
          manga.is_completed,
          manga.rating,
          manga.popularity,
          manga.release_year,
          manga.country_of_origin,
          manga.cover_image_url,
          manga.genres.map(&:name).join("|"),
          manga.created_at.strftime("%Y-%m-%d")
        ]
      end
    end
    puts "done (#{Manga.count} rows)"

    # -------------------------------------------------------------------------
    # genres.csv
    # -------------------------------------------------------------------------
    genres_path = output_dir.join("genres.csv")
    print "Exporting genres.csv ... "
    CSV.open(genres_path, "w") do |csv|
      csv << %w[ id name slug ]
      Genre.find_each { |g| csv << [ g.id, g.name, g.slug ] }
    end
    puts "done (#{Genre.count} rows)"

    # -------------------------------------------------------------------------
    # manga_genres.csv
    # -------------------------------------------------------------------------
    mg_path = output_dir.join("manga_genres.csv")
    print "Exporting manga_genres.csv ... "
    CSV.open(mg_path, "w") do |csv|
      csv << %w[ manga_id genre_id ]
      MangaGenre.find_each { |mg| csv << [ mg.manga_id, mg.genre_id ] }
    end
    puts "done (#{MangaGenre.count} rows)"

    # -------------------------------------------------------------------------
    # best_mangas.csv
    # -------------------------------------------------------------------------
    best_path = output_dir.join("best_mangas.csv")
    print "Exporting best_mangas.csv ... "
    CSV.open(best_path, "w") do |csv|
      csv << %w[ rank manga_id title score reason ]
      BestManga.includes(:manga).order(:rank).each do |b|
        csv << [ b.rank, b.manga_id, b.manga.title, b.score, b.reason ]
      end
    end
    puts "done (#{BestManga.count} rows)"

    # -------------------------------------------------------------------------
    # underrated_mangas.csv
    # -------------------------------------------------------------------------
    underrated_path = output_dir.join("underrated_mangas.csv")
    print "Exporting underrated_mangas.csv ... "
    CSV.open(underrated_path, "w") do |csv|
      csv << %w[ manga_id title score reason ]
      UnderratedManga.includes(:manga).each do |u|
        csv << [ u.manga_id, u.manga.title, u.score, u.reason ]
      end
    end
    puts "done (#{UnderratedManga.count} rows)"

    puts ""
    puts "=== Export selesai ==="
    puts "File tersimpan di: #{output_dir}"
    puts "  - mangas.csv          (#{Manga.count} rows)"
    puts "  - genres.csv          (#{Genre.count} rows)"
    puts "  - manga_genres.csv    (#{MangaGenre.count} rows)"
    puts "  - best_mangas.csv     (#{BestManga.count} rows)"
    puts "  - underrated_mangas.csv (#{UnderratedManga.count} rows)"
  end
end
