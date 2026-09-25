class MangasController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_manga, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /mangas
  # Query params:
  #   q           - search by title or author
  #   is_completed - filter by completed status (true/false)
  #   genre_id    - filter by genre
  #   page        - page number (default: 1)
  #   per_page    - items per page (default: 10, max: 100)
  def index
    @mangas = Manga
                .search(params[:q])
                .by_completed(params[:is_completed])
                .by_genre(params[:genre_id])

    render_paginated(@mangas)
  end

  # GET /mangas/1
  def show
    render json: @manga
  end

  # POST /mangas
  def create
    @manga = Manga.new(manga_params)
    @manga.save!

    render json: @manga, status: :created, location: @manga
  end

  # PATCH/PUT /mangas/1
  def update
    @manga.update!(manga_params)

    render json: @manga
  end

  # DELETE /mangas/1
  def destroy
    @manga.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_manga
      @manga = Manga.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def manga_params
      params.expect(manga: [ :title, :author, :synopsis, :chapet_count, :is_completed ])
    end
end
