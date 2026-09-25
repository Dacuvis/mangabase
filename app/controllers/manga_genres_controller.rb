class MangaGenresController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_manga_genre, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /manga_genres
  # Query params:
  #   manga_id - filter by manga
  #   genre_id - filter by genre
  #   page     - page number (default: 1)
  #   per_page - items per page (default: 10, max: 100)
  def index
    @manga_genres = MangaGenre
                      .by_manga(params[:manga_id])
                      .by_genre(params[:genre_id])

    render_paginated(@manga_genres)
  end

  # GET /manga_genres/1
  def show
    render json: @manga_genre
  end

  # POST /manga_genres
  def create
    @manga_genre = MangaGenre.new(manga_genre_params)
    @manga_genre.save!

    render json: @manga_genre, status: :created, location: @manga_genre
  end

  # PATCH/PUT /manga_genres/1
  def update
    @manga_genre.update!(manga_genre_params)

    render json: @manga_genre
  end

  # DELETE /manga_genres/1
  def destroy
    @manga_genre.destroy!
  end

  private

  def set_manga_genre
    @manga_genre = MangaGenre.find(params.expect(:id))
  end

  def manga_genre_params
    params.expect(manga_genre: [ :manga_id, :genre_id ])
  end
end
