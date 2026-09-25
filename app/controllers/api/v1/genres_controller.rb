class Api::V1::GenresController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_genre, only: %i[ show update destroy ]
  before_action :authenticate_admin!, except: [ :index, :show ]

  # GET /api/v1/genres
  def index
    @genres = Genre.search(params[:q])
    render_paginated(@genres)
  end

  # GET /api/v1/genres/1
  def show
    render json: @genre, serializer: GenreSerializer
  end

  # POST /api/v1/genres
  def create
    @genre = Genre.new(genre_params)
    @genre.save!

    render json: @genre, serializer: GenreSerializer, status: :created, location: [ :api, :v1, @genre ]
  end

  # PATCH/PUT /api/v1/genres/1
  def update
    @genre.update!(genre_params)

    render json: @genre, serializer: GenreSerializer
  end

  # DELETE /api/v1/genres/1
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
