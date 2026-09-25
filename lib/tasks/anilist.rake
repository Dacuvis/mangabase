require "net/http"
require "json"

namespace :anilist do
  desc "Import manga dari AniList GraphQL API. Usage: rails anilist:import[5000]"
  task :import, [ :limit ] => :environment do |_, args|
    # AniList hard limit: 5000 entri (page 1-100 x 50 per page)
    ANILIST_MAX = 5_000
    total_limit = [ (args[:limit] || 5_000).to_i, ANILIST_MAX ].min
    per_page    = 50
    total_pages = (total_limit.to_f / per_page).ceil

    if (args[:limit] || 0).to_i > ANILIST_MAX
      puts "⚠️  AniList membatasi maksimal #{ANILIST_MAX} entri. Limit disesuaikan."
    end

    puts "=== AniList Import ==="
    puts "Target : #{total_limit} manga"
    puts "Pages  : #{total_pages} (#{per_page}/page)"
    puts "====================="

    imported_manga  = 0
    imported_genres = 0
    skipped         = 0
    errors          = 0

    total_pages.times do |i|
      page = i + 1
      remaining = total_limit - imported_manga
      current_per_page = [ per_page, remaining ].min

      print "Page #{page}/#{total_pages} ... "

      begin
        result = fetch_page(page, current_per_page)
        media_list = result.dig("data", "Page", "media") || []

        break if media_list.empty?

        # Import genres dulu agar foreign key siap saat linking
        genre_count = import_genres_from_page(media_list)
        imported_genres += genre_count

        media_list.each do |media|
          begin
            import_manga(media)
            imported_manga += 1
          rescue ActiveRecord::RecordNotUnique
            skipped += 1
          rescue => e
            errors += 1
            puts "\n  [ERROR] #{media.dig('title', 'romaji')}: #{e.message}"
          end
        end

        puts "done (manga: #{imported_manga}, genres: #{imported_genres}, skipped: #{skipped})"

        # AniList rate limit: 90 req/menit → tunggu 0.7 detik per request
        sleep(0.7)

      rescue => e
        errors += 1
        puts "FAILED: #{e.message}"
        if e.message.include?("429") || e.message.include?("Too Many")
          puts "  Rate limited! Waiting 60s..."
          sleep(60)
          retry
        end
        sleep(2)
      end
    end

    puts ""
    puts "=== Import Manga Selesai ==="
    puts "Manga imported : #{imported_manga}"
    puts "Genres imported: #{imported_genres}"
    puts "Skipped (dup)  : #{skipped}"
    puts "Errors         : #{errors}"
    puts ""

    # Setelah import, isi best_mangas dan underrated_mangas
    Rake::Task["anilist:seed_best_mangas"].invoke
    Rake::Task["anilist:seed_underrated_mangas"].invoke
  end

  desc "Isi best_mangas dengan 10 manga rating tertinggi"
  task seed_best_mangas: :environment do
    puts "=== Seeding Best Mangas ==="

    BestManga.delete_all

    top10 = Manga
              .where.not(rating: nil)
              .order(rating: :desc, popularity: :asc)
              .limit(10)

    if top10.empty?
      puts "Tidak ada manga dengan rating. Pastikan import selesai dulu."
      next
    end

    top10.each_with_index do |manga, idx|
      BestManga.create!(
        rank:    idx + 1,
        score:   manga.rating,
        reason:  "Rated #{manga.rating}/10 on AniList with #{manga.popularity || 0} followers.",
        manga:   manga
      )
      puts "  ##{idx + 1} #{manga.title} (#{manga.rating})"
    end

    puts "Best Mangas selesai: #{BestManga.count} entri"
  end

  desc "Isi underrated_mangas: score >= 7.5 tapi popularity rank > 2000"
  task seed_underrated_mangas: :environment do
    puts "=== Seeding Underrated Mangas ==="

    UnderratedManga.delete_all

    # Ambil manga yang rating bagus tapi tidak sepopuler yang lain
    # popularity kecil = banyak follower, jadi kita ambil yang popularity > median
    median_popularity = Manga.where.not(popularity: nil).average(:popularity).to_i

    underrated = Manga
                   .where.not(rating: nil, popularity: nil)
                   .where("rating >= ?", 7.5)
                   .where("popularity < ?", median_popularity / 2)
                   .order(rating: :desc)
                   .limit(100)

    if underrated.empty?
      # Fallback: rating tinggi tapi popularity di bawah rata-rata
      underrated = Manga
                     .where.not(rating: nil)
                     .where("rating >= ?", 7.0)
                     .order(rating: :desc, popularity: :asc)
                     .limit(50)
    end

    count = 0
    underrated.each do |manga|
      UnderratedManga.create!(
        score:  manga.rating,
        reason: "High rating (#{manga.rating}/10) but underexposed — only #{manga.popularity || 0} followers on AniList.",
        manga:  manga
      )
      count += 1
    rescue ActiveRecord::RecordNotUnique
      next
    end

    puts "Underrated Mangas selesai: #{count} entri"
  end

  private

  ANILIST_API = "https://graphql.anilist.co"

  QUERY = <<~GRAPHQL
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(type: MANGA, sort: POPULARITY_DESC) {
          id
          title {
            romaji
            english
          }
          description(asHtml: false)
          chapters
          status
          averageScore
          popularity
          startDate {
            year
          }
          countryOfOrigin
          staff(perPage: 3) {
            edges {
              role
              node {
                name {
                  full
                }
              }
            }
          }
          genres
          coverImage {
            large
          }
        }
      }
    }
  GRAPHQL

  def fetch_page(page, per_page)
    uri  = URI(ANILIST_API)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"]       = "application/json"
    request.body = { query: QUERY, variables: { page: page, perPage: per_page } }.to_json

    response = http.request(request)

    raise "HTTP #{response.code}: #{response.body[0..200]}" unless response.code == "200"

    JSON.parse(response.body)
  end

  def import_manga(media)
    title = media.dig("title", "romaji") ||
            media.dig("title", "english") ||
            "Unknown ##{media['id']}"

    author        = extract_author(media["staff"])
    synopsis      = media["description"]&.gsub(/<[^>]+>/, "")&.strip
    chapter_count = media["chapters"]
    is_completed  = media["status"] == "FINISHED"

    # averageScore dari AniList skala 0-100, konversi ke 0-10
    raw_score = media["averageScore"]
    rating    = raw_score ? (raw_score / 10.0).round(1) : nil

    popularity        = media["popularity"]
    release_year      = media.dig("startDate", "year")
    country_of_origin = media["countryOfOrigin"]&.upcase&.slice(0, 2)
    cover_image_url   = media.dig("coverImage", "large")

    manga = Manga.find_or_initialize_by(title: title)
    manga.assign_attributes(
      author:            author,
      synopsis:          synopsis,
      chapter_count:     chapter_count,
      is_completed:      is_completed,
      rating:            rating,
      popularity:        popularity,
      release_year:      release_year,
      country_of_origin: country_of_origin,
      cover_image_url:   cover_image_url
    )
    manga.save!

    # Hubungkan genres
    (media["genres"] || []).each do |genre_name|
      genre = Genre.find_by(name: genre_name)
      next unless genre

      MangaGenre.find_or_create_by!(manga: manga, genre: genre)
    rescue ActiveRecord::RecordNotUnique
      next
    end
  end

  def import_genres_from_page(media_list)
    genre_names = media_list.flat_map { |m| m["genres"] || [] }.uniq
    count = 0
    genre_names.each do |name|
      next if name.blank?

      slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      genre = Genre.find_or_initialize_by(name: name)
      if genre.new_record?
        genre.slug = slug
        genre.save!
        count += 1
      end
    rescue ActiveRecord::RecordNotUnique
      next
    end
    count
  end

  def extract_author(staff)
    return nil if staff.nil?

    edges = staff["edges"] || []
    story = edges.find { |e| e["role"]&.match?(/story/i) }
    art   = edges.find { |e| e["role"]&.match?(/art/i) }
    first = edges.first

    (story || art || first)&.dig("node", "name", "full")
  end
end
