require 'google-id-token'

class Api::V1::AuthenticationController < ApplicationController
  wrap_parameters :user, include: [:email, :password, :password_confirmation, :first_name, :last_name]

  skip_before_action :authenticate_request!, only: [:login, :register, :google_login]

  def google_login
    validator = GoogleIDToken::Validator.new
    begin
      # Check if token is valid
      # Note: Frontend must send id_token
      payload = validator.check(params[:id_token], ENV['GOOGLE_CLIENT_ID'])
      
      # Find or create user
      user = User.find_or_initialize_by(email: payload['email'])
      
      # Update user details from Google
      user.google_id = payload['sub']
      user.first_name ||= payload['given_name']
      user.last_name ||= payload['family_name']
      
      if user.save
        render json: { 
          api_key: user.api_key, 
          email: user.email, 
          role: user.role,
          first_name: user.first_name,
          last_name: user.last_name,
          is_pro: user.pro?,
          stripe_subscription_id: user.stripe_subscription_id
        }, status: :ok
      else
        render json: { error: user.errors.full_messages }, status: :unprocessable_entity
      end
    rescue GoogleIDToken::ValidationError => e
      render json: { error: "Invalid Google token: #{e.message}" }, status: :unauthorized
    rescue StandardError => e
      render json: { error: "Google Auth Error: #{e.message}" }, status: :internal_server_error
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      render json: { 
        api_key: user.api_key, 
        email: user.email, 
        role: user.role,
        first_name: user.first_name,
        last_name: user.last_name,
        is_pro: user.pro?,
        stripe_subscription_id: user.stripe_subscription_id
      }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
  
  def me
    render json: { 
      api_key: current_user.api_key, 
      email: current_user.email, 
      role: current_user.role,
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      is_pro: current_user.pro?,
      stripe_subscription_id: current_user.stripe_subscription_id
    }, status: :ok
  end

  def update_me
    if current_user.update(user_params.except(:password, :password_confirmation))
      render json: { 
        message: 'Profile updated successfully',
        user: {
          email: current_user.email,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          role: current_user.role,
          is_pro: current_user.pro?,
          stripe_subscription_id: current_user.stripe_subscription_id
        }
      }, status: :ok
    else
      render json: current_user.errors, status: :unprocessable_entity
    end
  end

  def register
    user = User.new(user_params)
    authorize user

    if user.save
      render json: { 
        api_key: user.api_key, 
        email: user.email, 
        role: user.role,
        first_name: user.first_name,
        last_name: user.last_name,
        is_pro: user.pro?,
        stripe_subscription_id: user.stripe_subscription_id
      }, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    if params[:user]
      params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
    else
      params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
    end
  end
end
