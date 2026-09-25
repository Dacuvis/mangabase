class Api::V1::MangaGenresController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_manga_genre, only: %i[ show update destroy ]
  before_action :authenticate_admin!, except: [ :index, :show ]

  # GET /api/v1/manga_genres
  def index
    @manga_genres = MangaGenre
                      .includes(:manga, :genre)
                      .by_manga(params[:manga_id])
                      .by_genre(params[:genre_id])

    render_paginated(@manga_genres)
  end

  # GET /api/v1/manga_genres/1
  def show
    render json: @manga_genre, serializer: MangaGenreSerializer
  end

  # POST /api/v1/manga_genres
  def create
    @manga_genre = MangaGenre.new(manga_genre_params)
    @manga_genre.save!

    render json: @manga_genre, serializer: MangaGenreSerializer,
           status: :created, location: [ :api, :v1, @manga_genre ]
  end

  # PATCH/PUT /api/v1/manga_genres/1
  def update
    @manga_genre.update!(manga_genre_params)

    render json: @manga_genre, serializer: MangaGenreSerializer
  end

  # DELETE /api/v1/manga_genres/1
  def destroy
    @manga_genre.destroy!
  end

  private

  def set_manga_genre
    @manga_genre = MangaGenre.includes(:manga, :genre).find(params.expect(:id))
  end

  def manga_genre_params
    params.expect(manga_genre: [ :manga_id, :genre_id ])
  end
end
