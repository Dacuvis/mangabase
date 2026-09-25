class BestMangasController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_best_manga, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /best_mangas
  # Query params:
  #   manga_id  - filter by manga
  #   min_rank  - filter rank minimum
  #   max_rank  - filter rank maksimum
  #   min_score - filter score minimum
  #   max_score - filter score maksimum
  #   page      - page number (default: 1)
  #   per_page  - items per page (default: 10, max: 100)
  def index
    @best_mangas = BestManga
                     .by_manga(params[:manga_id])
                     .min_rank(params[:min_rank])
                     .max_rank(params[:max_rank])
                     .min_score(params[:min_score])
                     .max_score(params[:max_score])

    render_paginated(@best_mangas)
  end

  # GET /best_mangas/1
  def show
    render json: @best_manga
  end

  # POST /best_mangas
  def create
    @best_manga = BestManga.new(best_manga_params)
    @best_manga.save!

    render json: @best_manga, status: :created, location: @best_manga
  end

  # PATCH/PUT /best_mangas/1
  def update
    @best_manga.update!(best_manga_params)

    render json: @best_manga
  end

  # DELETE /best_mangas/1
  def destroy
    @best_manga.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_best_manga
      @best_manga = BestManga.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def best_manga_params
      params.expect(best_manga: [ :rank, :score, :reason, :manga_id ])
    end
end
