class GenresController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_genre, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /genres
  # Query params:
  #   q        - search by name or slug
  #   page     - page number (default: 1)
  #   per_page - items per page (default: 10, max: 100)
  def index
    @genres = Genre.search(params[:q])

    render_paginated(@genres)
  end

  # GET /genres/1
  def show
    render json: @genre
  end

  # POST /genres
  def create
    @genre = Genre.new(genre_params)
    @genre.save!

    render json: @genre, status: :created, location: @genre
  end

  # PATCH/PUT /genres/1
  def update
    @genre.update!(genre_params)

    render json: @genre
  end

  # DELETE /genres/1
  def destroy
    @genre.destroy!
  end

  private

  def set_genre
    @genre = Genre.find(params.expect(:id))
  end

  def genre_params
    params.expect(genre: [ :name, :slug ])
  end
end
