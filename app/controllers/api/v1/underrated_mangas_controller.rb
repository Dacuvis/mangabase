class Api::V1::UnderratedMangasController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_underrated_manga, only: %i[ show update destroy ]
  before_action :authenticate_admin!, except: [ :index, :show ]

  # GET /api/v1/underrated_mangas
  def index
    @underrated_mangas = UnderratedManga
                           .includes(:manga)
                           .by_manga(params[:manga_id])
                           .min_score(params[:min_score])
                           .max_score(params[:max_score])

    render_paginated(@underrated_mangas)
  end

  # GET /api/v1/underrated_mangas/1
  def show
    render json: @underrated_manga, serializer: UnderratedMangaSerializer
  end

  # POST /api/v1/underrated_mangas
  def create
    @underrated_manga = UnderratedManga.new(underrated_manga_params)
    @underrated_manga.save!

    render json: @underrated_manga, serializer: UnderratedMangaSerializer,
           status: :created, location: [ :api, :v1, @underrated_manga ]
  end

  # PATCH/PUT /api/v1/underrated_mangas/1
  def update
    @underrated_manga.update!(underrated_manga_params)

    render json: @underrated_manga, serializer: UnderratedMangaSerializer
  end

  # DELETE /api/v1/underrated_mangas/1
  def destroy
    @underrated_manga.destroy!
  end

  private

  def set_underrated_manga
    @underrated_manga = UnderratedManga.includes(:manga).find(params.expect(:id))
  end

  def underrated_manga_params
    params.expect(underrated_manga: [ :rank, :score, :reason, :manga_id ])
  end
end
