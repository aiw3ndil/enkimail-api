class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Pundit: rescue not authorized errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Ensure all API requests are authenticated by default
  before_action :authenticate_request!

  private

  def current_user
    @current_user ||= authenticate_user_from_api_key
  end

  def authenticate_request!
    render json: { error: 'Not Authorized' }, status: :unauthorized unless current_user
  end

  def authenticate_user_from_api_key
    api_key = request.headers['Authorization']&.split(' ')&.last
    puts "API Key from header: #{api_key}" # Debugging line
    User.find_by(api_key: api_key)
  end

  def user_not_authorized
    render json: { error: "You are not authorized to perform this action." }, status: :forbidden
  end
end
