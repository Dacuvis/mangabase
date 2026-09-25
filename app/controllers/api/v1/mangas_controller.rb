class Api::V1::MangasController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_manga, only: %i[ show update destroy recommendations ]
  before_action :authenticate_admin!, except: [ :index, :show, :recommendations ]

  # GET /api/v1/mangas
  # Query params:
  #   q            - search by title or author (FULLTEXT)
  #   is_completed - filter by completed status (true/false)
  #   genre_id     - filter by genre
  #   page         - page number (default: 1)
  #   per_page     - items per page (default: 10, max: 100)
  def index
    @mangas = Manga
                .includes(:genres)
                .search(params[:q])
                .by_completed(params[:is_completed])
                .by_genre(params[:genre_id])

    render_paginated(@mangas)
  end

  # GET /api/v1/mangas/1
  def show
    render json: @manga, serializer: MangaSerializer
  end

  # GET /api/v1/mangas/1/recommendations?top_n=10
  def recommendations
    top_n = [ (params[:top_n] || 10).to_i, 50 ].min

    uri = URI("#{ENV.fetch('ML_SERVICE_URL', 'http://localhost:8000')}/recommend")
    uri.query = URI.encode_www_form(manga_id: @manga.id, top_n: top_n)

    http          = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl  = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 10

    response = http.get(uri.request_uri)

    if response.code == "200"
      render json: JSON.parse(response.body)
    elsif response.code == "404"
      render json: { error: "Manga tidak ditemukan di model rekomendasi" }, status: :not_found
    else
      render json: { error: "ML service error" }, status: :bad_gateway
    end
  rescue Errno::ECONNREFUSED, Net::OpenTimeout
    render json: { error: "Recommendation service tidak tersedia" }, status: :service_unavailable
  end

  # POST /api/v1/mangas
  def create
    @manga = Manga.new(manga_params)
    @manga.save!

    render json: @manga, serializer: MangaSerializer, status: :created, location: [ :api, :v1, @manga ]
  end

  # PATCH/PUT /api/v1/mangas/1
  def update
    @manga.update!(manga_params)

    render json: @manga, serializer: MangaSerializer
  end

  # DELETE /api/v1/mangas/1
  def destroy
    @manga.destroy!
  end

  private

  def set_manga
    @manga = Manga.includes(:genres).find(params.expect(:id))
  end

  def manga_params
    params.expect(manga: [ :title, :author, :synopsis, :chapter_count, :is_completed,
                           :rating, :popularity, :release_year, :country_of_origin,
                           :cover_image_url ])
  end
end
