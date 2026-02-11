class EmailsController < ApplicationController
  def create
    authorize :email # Enforce Pundit policy
    # For now, we'll just simulate sending an email
    # In a real application, you would:
    # 1. Validate parameters (e.g., recipient email format)
    # 2. Potentially save the email details to a database
    # 3. Enqueue a background job (e.g., using Sidekiq) to send the email

    to = params.require(:to)
    template_name = params.require(:template_name)
    data = (params.permit(data: {}).to_h[:data] || {}).to_h # Ensure data is a plain hash for Sidekiq

    # Enqueue a background job to send the email
    EmailSenderWorker.perform_async(to, template_name, data)

    render json: { status: 'success', message: 'Email queued for sending using template', to: to, template_name: template_name, data: data }, status: :accepted
  rescue ActionController::ParameterMissing => e
    render json: { status: 'error', message: e.message }, status: :bad_request
  rescue => e
    render json: { status: 'error', message: e.message }, status: :internal_server_error
  end
end
