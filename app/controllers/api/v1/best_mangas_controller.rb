class Api::V1::BestMangasController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_best_manga, only: %i[ show update destroy ]
  before_action :authenticate_admin!, except: [ :index, :show ]

  # GET /api/v1/best_mangas
  def index
    @best_mangas = BestManga
                     .includes(:manga)
                     .by_manga(params[:manga_id])
                     .min_rank(params[:min_rank])
                     .max_rank(params[:max_rank])
                     .min_score(params[:min_score])
                     .max_score(params[:max_score])

    render_paginated(@best_mangas)
  end

  # GET /api/v1/best_mangas/1
  def show
    render json: @best_manga, serializer: BestMangaSerializer
  end

  # POST /api/v1/best_mangas
  def create
    @best_manga = BestManga.new(best_manga_params)
    @best_manga.save!

    render json: @best_manga, serializer: BestMangaSerializer,
           status: :created, location: [ :api, :v1, @best_manga ]
  end

  # PATCH/PUT /api/v1/best_mangas/1
  def update
    @best_manga.update!(best_manga_params)

    render json: @best_manga, serializer: BestMangaSerializer
  end

  # DELETE /api/v1/best_mangas/1
  def destroy
    @best_manga.destroy!
  end

  private

  def set_best_manga
    @best_manga = BestManga.includes(:manga).find(params.expect(:id))
  end

  def best_manga_params
    params.expect(best_manga: [ :rank, :score, :reason, :manga_id ])
  end
end
