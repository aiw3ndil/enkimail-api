class Api::V1::AuthenticationController < ApplicationController

  skip_before_action :authenticate_request!, only: [:login, :register]

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      render json: { api_key: user.api_key, email: user.email, role: user.role }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
  
  def me
    render json: { api_key: current_user.api_key, email: current_user.email, role: current_user.role }, status: :ok
  end

  def register
    user = User.new(user_params)
    authorize user

    if user.save
      render json: { api_key: user.api_key, email: user.email, role: user.role }, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end
end
