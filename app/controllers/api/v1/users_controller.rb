class Api::V1::UsersController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable

  before_action :set_user, only: %i[ show update destroy ]
  before_action :authenticate_admin!, except: [ :index, :show ]

  # GET /api/v1/users
  def index
    @users = User.search(params[:q])
    render_paginated(@users)
  end

  # GET /api/v1/users/1
  def show
    render json: @user, serializer: UserSerializer
  end

  # POST /api/v1/users
  def create
    @user = User.new(user_params)
    @user.save!

    render json: @user, serializer: UserSerializer, status: :created, location: [ :api, :v1, @user ]
  end

  # PATCH/PUT /api/v1/users/1
  def update
    @user.update!(user_params)

    render json: @user, serializer: UserSerializer
  end

  # DELETE /api/v1/users/1
  def destroy
    @user.destroy!
  end

  private

  def set_user
    @user = User.find(params.expect(:id))
  end

  def user_params
    params.expect(user: [ :name, :email ])
  end
end
