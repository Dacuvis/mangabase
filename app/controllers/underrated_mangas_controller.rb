class UnderratedMangasController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_underrated_manga, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /underrated_mangas
  # Query params:
  #   manga_id  - filter by manga
  #   min_score - filter score minimum
  #   max_score - filter score maksimum
  #   page      - page number (default: 1)
  #   per_page  - items per page (default: 10, max: 100)
  def index
    @underrated_mangas = UnderratedManga
                           .by_manga(params[:manga_id])
                           .min_score(params[:min_score])
                           .max_score(params[:max_score])

    render_paginated(@underrated_mangas)
  end

  # GET /underrated_mangas/1
  def show
    render json: @underrated_manga
  end

  # POST /underrated_mangas
  def create
    @underrated_manga = UnderratedManga.new(underrated_manga_params)
    @underrated_manga.save!

    render json: @underrated_manga, status: :created, location: @underrated_manga
  end

  # PATCH/PUT /underrated_mangas/1
  def update
    @underrated_manga.update!(underrated_manga_params)

    render json: @underrated_manga
  end

  # DELETE /underrated_mangas/1
  def destroy
    @underrated_manga.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_underrated_manga
      @underrated_manga = UnderratedManga.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def underrated_manga_params
      params.expect(underrated_manga: [ :rank, :score, :reason, :manga_id ])
    end
end
