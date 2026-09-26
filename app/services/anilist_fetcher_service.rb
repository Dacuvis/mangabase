# frozen_string_literal: true

require "net/http"
require "json"
require "set"

class AnilistFetcherService
  ANILIST_API = URI("https://graphql.anilist.co")
  PER_PAGE = 50
  MAX_PAGES_PER_WINDOW = 100 # AniList page depth limit: 100 * 50 = 5,000 entries
  DEFAULT_SLEEP = 0.7        # 90 requests/min rate limit (0.7s ~ 85 req/min)
  RATE_LIMIT_SLEEP = 60      # Wait on HTTP 429

  # Query for the first window (no popularity_lesser filter)
  INITIAL_QUERY = <<~GRAPHQL
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          currentPage
          hasNextPage
          lastPage
        }
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

  # Query for subsequent windows (using popularity_lesser to bypass the 5,000 page depth limit)
  WINDOWED_QUERY = <<~GRAPHQL
    query ($page: Int, $perPage: Int, $popularityLesser: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          currentPage
          hasNextPage
          lastPage
        }
        media(type: MANGA, sort: POPULARITY_DESC, popularity_lesser: $popularityLesser) {
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

  class << self
    # Fetch manga data from AniList without hard limit (returns array of hashes)
    def fetch_all_manga(limit: 5_000, start_popularity: nil, verbose: true)
      results = []
      fetch_in_batches(limit: limit, start_popularity: start_popularity, verbose: verbose) do |media_list|
        results.concat(media_list)
      end
      results
    end

    # Fetch and import directly into ActiveRecord models (Manga, Genre, MangaGenre)
    def import(limit: 5_000, resume: false, verbose: true)
      start_popularity = nil

      if resume
        min_pop = Manga.where.not(popularity: nil).minimum(:popularity)
        if min_pop
          start_popularity = min_pop + 1
          puts "⏩ Melanjutkan import dari popularitas <= #{min_pop}..." if verbose
        else
          puts "ℹ️ Tidak ada data manga di DB untuk di-resume. Memulai dari awal." if verbose
        end
      end

      stats = {
        imported_manga:  0,
        updated_manga:   0,
        imported_genres: 0,
        skipped:         0,
        errors:          0
      }

      puts "=== AniList Import Dimulai ===" if verbose
      puts "Target import: #{limit ? "#{limit} manga" : 'Semua manga (tanpa batas)'}" if verbose

      fetch_in_batches(limit: limit, start_popularity: start_popularity, verbose: verbose) do |batch|
        # 1. Import genres first so foreign keys are ready
        genre_count = import_genres(batch)
        stats[:imported_genres] += genre_count

        # 2. Import manga
        batch.each do |media|
          begin
            record = import_single_manga(media)
            if record[:created]
              stats[:imported_manga] += 1
            else
              stats[:updated_manga] += 1
            end
          rescue ActiveRecord::RecordNotUnique
            stats[:skipped] += 1
          rescue => e
            stats[:errors] += 1
            puts "\n  [ERROR] #{media.dig('title', 'romaji')}: #{e.message}" if verbose
          end
        end
      end

      puts "" if verbose
      puts "=== Import AniList Selesai ===" if verbose
      puts "Manga baru diimpor : #{stats[:imported_manga]}" if verbose
      puts "Manga di-update    : #{stats[:updated_manga]}" if verbose
      puts "Genre baru         : #{stats[:imported_genres]}" if verbose
      puts "Skipped (duplicate): #{stats[:skipped]}" if verbose
      puts "Error              : #{stats[:errors]}" if verbose
      puts "Total Manga di DB  : #{Manga.count}" if verbose

      stats
    end

    # Core engine: Windowed keyset pagination iterating over AniList GraphQL
    def fetch_in_batches(limit: 5_000, start_popularity: nil, verbose: true)
      seen_ids = Set.new
      total_processed = 0
      current_window_page = 1
      popularity_lesser = start_popularity
      window_number = 1

      http = Net::HTTP.new(ANILIST_API.host, ANILIST_API.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10

      loop do
        remaining = limit ? (limit - total_processed) : PER_PAGE
        break if remaining <= 0

        current_per_page = [ PER_PAGE, remaining ].min

        # Execute GraphQL request with retry logic
        data = execute_request_with_retry(http, current_window_page, current_per_page, popularity_lesser, verbose)
        media_list = data.dig("data", "Page", "media") || []
        page_info  = data.dig("data", "Page", "pageInfo") || {}

        break if media_list.empty?

        # Filter out duplicates that might occur on boundary conditions
        unique_batch = media_list.reject { |m| seen_ids.include?(m["id"]) }
        unique_batch.each { |m| seen_ids.add(m["id"]) }

        if unique_batch.any?
          yield unique_batch if block_given?
          total_processed += unique_batch.size

          if verbose
            last_item = unique_batch.last
            print "\r[Window #{window_number} | Page #{current_window_page}/#{MAX_PAGES_PER_WINDOW}] " \
                  "Pop: #{last_item['popularity']} | Terproses: #{total_processed}/#{limit || '∞'} manga   "
            $stdout.flush
          end
        end

        break if limit && total_processed >= limit

        has_next_page = page_info["hasNextPage"]
        last_pop = media_list.last["popularity"]

        # AniList Depth Limit Handling:
        # AniList blocks requests where page * perPage > 5000.
        # When page reaches 100, we advance the Keyset Window using popularity_lesser:
        if current_window_page >= MAX_PAGES_PER_WINDOW || (!has_next_page && popularity_lesser.nil?)
          # Move to the next window
          popularity_lesser = (last_pop || 0) + 1
          current_window_page = 1
          window_number += 1
          puts "\n🔄 Membuka Window Keyset #{window_number} (popularity_lesser: #{popularity_lesser}) untuk melewati batas 5.000..." if verbose
        elsif !has_next_page
          # Reached end of data in this window and no more pages
          if last_pop && last_pop > 0
            popularity_lesser = last_pop
            current_window_page = 1
            window_number += 1
            puts "\n🔄 Lanjut ke range berikutnya (popularity_lesser: #{popularity_lesser})..." if verbose
          else
            break
          end
        else
          current_window_page += 1
        end

        sleep(DEFAULT_SLEEP)
      end

      puts "" if verbose
    end

    private

    def execute_request_with_retry(http, page, per_page, popularity_lesser, verbose)
      query = popularity_lesser ? WINDOWED_QUERY : INITIAL_QUERY
      variables = { page: page, perPage: per_page }
      variables[:popularityLesser] = popularity_lesser if popularity_lesser

      request = Net::HTTP::Post.new(ANILIST_API)
      request["Content-Type"] = "application/json"
      request["Accept"]       = "application/json"
      request.body            = { query: query, variables: variables }.to_json

      retries = 0
      begin
        response = http.request(request)

        if response.code == "429"
          puts "\n⚠️  AniList Rate Limit (429)! Menunggu #{RATE_LIMIT_SLEEP} detik..." if verbose
          sleep(RATE_LIMIT_SLEEP)
          return execute_request_with_retry(http, page, per_page, popularity_lesser, verbose)
        end

        raise "HTTP #{response.code}: #{response.body[0..200]}" unless response.code == "200"

        JSON.parse(response.body)
      rescue Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNRESET => e
        retries += 1
        if retries <= 3
          puts "\n⚠️  Koneksi timeout (#{e.message}), mencoba ulang (#{retries}/3)..." if verbose
          sleep(2 * retries)
          retry
        else
          raise
        end
      end
    end

    def import_single_manga(media)
      title = media.dig("title", "romaji") ||
              media.dig("title", "english") ||
              "Unknown ##{media['id']}"

      author        = extract_author(media["staff"])
      synopsis      = media["description"]&.gsub(/<[^>]+>/, "")&.strip
      chapter_count = media["chapters"]
      is_completed  = media["status"] == "FINISHED"

      raw_score = media["averageScore"]
      rating    = raw_score ? (raw_score / 10.0).round(1) : nil

      popularity        = media["popularity"]
      release_year      = media.dig("startDate", "year")
      country_of_origin = media["countryOfOrigin"]&.upcase&.slice(0, 2)
      cover_image_url   = media.dig("coverImage", "large")

      manga = Manga.find_or_initialize_by(title: title)
      is_new = manga.new_record?

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

      (media["genres"] || []).each do |genre_name|
        genre = Genre.find_by(name: genre_name)
        next unless genre

        MangaGenre.find_or_create_by!(manga: manga, genre: genre)
      rescue ActiveRecord::RecordNotUnique
        next
      end

      { manga: manga, created: is_new }
    end

    def import_genres(media_list)
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
end
