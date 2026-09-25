class Api::V1::ReadingListsController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_reading_list, only: %i[ show update destroy ]
  before_action :authenticate_any_key!, only: %i[ create update destroy ]
  before_action :authorize_owner!, only: %i[ update destroy ]

  # GET /api/v1/reading_lists
  def index
    @reading_lists = ReadingList
                       .by_user(params[:user_id])
                       .by_manga(params[:manga_id])
                       .by_status(params[:status])

    render_paginated(@reading_lists)
  end

  # GET /api/v1/reading_lists/1
  def show
    render json: @reading_list, serializer: ReadingListSerializer
  end

  # POST /api/v1/reading_lists
  def create
    uid = resolve_owner_id
    return if performed?

    @reading_list = ReadingList.new(reading_list_params.merge(user_id: uid))
    @reading_list.save!

    render json: @reading_list, serializer: ReadingListSerializer,
           status: :created, location: [ :api, :v1, @reading_list ]
  end

  # PATCH/PUT /api/v1/reading_lists/1
  def update
    @reading_list.update!(reading_list_params.except(:user_id))

    render json: @reading_list, serializer: ReadingListSerializer
  end

  # DELETE /api/v1/reading_lists/1
  def destroy
    @reading_list.destroy!
  end

  private

  def set_reading_list
    @reading_list = ReadingList.find(params.expect(:id))
  end

  def resolve_owner_id
    if current_api_role == :admin
      uid = reading_list_params[:user_id]
      if uid.blank?
        render json: { error: "user_id is required" }, status: :unprocessable_entity
        return nil
      end
      uid
    else
      authenticated_user_id
    end
  end

  def authorize_owner!
    return if current_api_role == :admin

    uid = authenticated_user_id
    return if performed?

    return if @reading_list.user_id == uid

    render json: { error: "Forbidden: you do not own this reading list" }, status: :forbidden
  end

  def reading_list_params
    params.expect(reading_list: [ :user_id, :manga_id, :status, :progress_chapter ])
  end
end
