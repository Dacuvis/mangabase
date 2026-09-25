class UsersController < ApplicationController
  include ApiKeyAuthenticatable
  include Paginatable
  before_action :set_user, only: %i[ show update destroy ]
  before_action :authenticate_api_key!, except: [ :index, :show ]

  # GET /users
  # Query params:
  #   q        - search by name or email
  #   page     - page number (default: 1)
  #   per_page - items per page (default: 10, max: 100)
  def index
    @users = User.search(params[:q])

    render_paginated(@users)
  end

  # GET /users/1
  def show
    render json: @user
  end

  # POST /users
  def create
    @user = User.new(user_params)
    @user.save!

    render json: @user, status: :created, location: @user
  end

  # PATCH/PUT /users/1
  def update
    @user.update!(user_params)

    render json: @user
  end

  # DELETE /users/1
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
