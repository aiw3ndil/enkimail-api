class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Pundit: rescue not authorized errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Ensure all API requests are authenticated by default
  before_action :authenticate_request! # Will be uncommented and potentially made configurable later

  private

  # Placeholder for a User object
  # In a real application, this would be an ActiveRecord model
  User = Struct.new(:id, :name, :token)

  def current_user
    @current_user ||= authenticate_user_from_token
  end

  def authenticate_request!
    # Ensure current_user is set, or raise an error
    render json: { error: 'Not Authorized' }, status: :unauthorized unless current_user
  end

  def authenticate_user_from_token
    # Check for Authorization header
    token = request.headers['Authorization']&.split(' ')&.last

    # For now, a hardcoded token for demonstration purposes
    # In a real app, you'd fetch this from a database or a secure config
    if token == 'my_secret_api_token'
      User.new(1, 'API User', token) # Return a placeholder user
    else
      nil # No user found
    end
  end

  def user_not_authorized
    render json: { error: "You are not authorized to perform this action." }, status: :forbidden
  end
end
