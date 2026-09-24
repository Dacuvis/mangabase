class BestMangasController < ApplicationController
  include ApiKeyAuthenticatable
  before_action :set_best_manga, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [:index, :show]

  # GET /best_mangas
  def index
    @best_mangas = BestManga.all

    render json: @best_mangas
  end

  # GET /best_mangas/1
  def show
    render json: @best_manga
  end

  # POST /best_mangas
  def create
    @best_manga = BestManga.new(best_manga_params)

    if @best_manga.save
      render json: @best_manga, status: :created, location: @best_manga
    else
      render json: @best_manga.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /best_mangas/1
  def update
    if @best_manga.update(best_manga_params)
      render json: @best_manga
    else
      render json: @best_manga.errors, status: :unprocessable_content
    end
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
