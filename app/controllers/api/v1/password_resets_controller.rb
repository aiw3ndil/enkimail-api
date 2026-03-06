class Api::V1::PasswordResetsController < ApplicationController
  skip_before_action :authenticate_request!

  def create
    user = User.find_by(email: params[:email])
    
    if user
      user.generate_password_reset_token!
      UserMailer.password_reset_email(user).deliver_later
    end
    
    # We always return 200 to prevent user enumeration
    render json: { message: 'If that email address exists, we have sent a password reset link to it.' }, status: :ok
  end

  def update
    user = User.find_by(reset_password_token: params[:token])

    if user && user.password_reset_token_valid?
      if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        user.clear_password_reset_token!
        render json: { message: 'Password has been reset successfully.' }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Password reset token is invalid or has expired.' }, status: :unauthorized
    end
  end
end
