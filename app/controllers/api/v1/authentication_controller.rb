class Api::V1::AuthenticationController < ApplicationController
  wrap_parameters :user, include: [:email, :password, :password_confirmation, :first_name, :last_name]

  skip_before_action :authenticate_request!, only: [:login, :register]

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
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
