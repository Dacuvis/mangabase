# frozen_string_literal: true

namespace :anilist do
  desc "Import manga dari AniList GraphQL API tanpa batas 5.000 (Keyset Windowing). Usage: rails anilist:import[10000] atau rails anilist:import[5000,true]"
  task :import, [ :limit, :resume ] => :environment do |_, args|
    limit_arg = args[:limit]
    limit     = limit_arg.present? ? limit_arg.to_i : 5_000
    resume    = args[:resume].to_s.strip.downcase == "true"

    puts "=== AniList Manga Importer (Bypass 5.000 Hard Limit) ==="
    puts "Limit  : #{limit > 0 ? "#{limit} manga" : 'Semua manga (tanpa batas)'}"
    puts "Resume : #{resume ? 'Ya (melanjutkan dari popularitas terendah di DB)' : 'Tidak (mulai dari manga terpopuler)'}"
    puts "=========================================================="

    AnilistFetcherService.import(limit: (limit > 0 ? limit : nil), resume: resume, verbose: true)

    # Setelah import, isi best_mangas dan underrated_mangas
    Rake::Task["anilist:seed_best_mangas"].invoke
    Rake::Task["anilist:seed_underrated_mangas"].invoke
  end

  desc "Lanjutkan import manga dari posisi database saat ini sampai selesai atau sesuai limit. Usage: rails anilist:resume atau rails anilist:resume[5000]"
  task :resume, [ :limit ] => :environment do |_, args|
    limit_arg = args[:limit]
    limit     = limit_arg.present? ? limit_arg.to_i : 0

    puts "=== AniList Manga Resume Importer ==="
    puts "Limit  : #{limit > 0 ? "#{limit} manga" : 'Semua sisa manga sampai selesai (tanpa batas)'}"
    puts "Posisi : Melanjutkan dari popularitas terendah saat ini di database"
    puts "====================================="

    AnilistFetcherService.import(limit: (limit > 0 ? limit : nil), resume: true, verbose: true)

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
end
