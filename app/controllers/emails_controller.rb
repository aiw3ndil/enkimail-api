class EmailsController < ApplicationController
  def create
    authorize :email # Enforce Pundit policy

    to = params.require(:to)
    template_name = params.require(:template_name)
    data = (params.permit(data: {}).to_h[:data] || {}).to_h # Ensure data is a plain hash for Sidekiq

    # Find or Create Contact for the current_user
    contact = current_user.contacts.find_or_create_by(email: to)
    unless contact.persisted?
      return render json: { status: 'error', message: "Could not find or create contact with email '#{to}'." }, status: :unprocessable_entity
    end

    # Enforce transactional limit (300 for free plan)
    unless current_user.transactional_emails_count < 300
      return render json: { status: 'error', message: "Monthly transactional email limit reached (300 emails). Upgrade your plan to increase your limit." }, status: :too_many_requests
    end

    email_template = EmailTemplate.find_by(name: template_name)
    unless email_template
      return render json: { status: 'error', message: "EmailTemplate with name '#{template_name}' not found." }, status: :not_found
    end

    # Enqueue a background job to send the email
    # For individual emails, campaign_id is nil
    # Correct order: to, template_name, contact_id, data, campaign_id, email_template_id
    SendCampaignEmailJob.perform_later(to, template_name, contact.id, data, nil, email_template.id)


    render json: { status: 'success', message: 'Email queued for sending using template', to: to, template_name: template_name, data: data }, status: :accepted
  rescue ActionController::ParameterMissing => e
    render json: { status: 'error', message: e.message }, status: :bad_request
  rescue => e
    Rails.logger.error "EmailsController: Error sending individual email: #{e.message}"
    render json: { status: 'error', message: e.message }, status: :internal_server_error
  end
end
