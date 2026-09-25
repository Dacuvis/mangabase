class ReadingListsController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_reading_list, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /reading_lists
  # Query params:
  #   user_id  - filter by user
  #   manga_id - filter by manga
  #   status   - filter by status (misal: reading, completed, plan_to_read)
  #   page     - page number (default: 1)
  #   per_page - items per page (default: 10, max: 100)
  def index
    @reading_lists = ReadingList
                       .by_user(params[:user_id])
                       .by_manga(params[:manga_id])
                       .by_status(params[:status])

    render_paginated(@reading_lists)
  end

  # GET /reading_lists/1
  def show
    render json: @reading_list
  end

  # POST /reading_lists
  def create
    @reading_list = ReadingList.new(reading_list_params)
    @reading_list.save!

    render json: @reading_list, status: :created, location: @reading_list
  end

  # PATCH/PUT /reading_lists/1
  def update
    @reading_list.update!(reading_list_params)

    render json: @reading_list
  end

  # DELETE /reading_lists/1
  def destroy
    @reading_list.destroy!
  end

  private

  def set_reading_list
    @reading_list = ReadingList.find(params.expect(:id))
  end

  def reading_list_params
    params.expect(reading_list: [ :user_id, :manga_id, :status, :progress_chapter ])
  end
end
