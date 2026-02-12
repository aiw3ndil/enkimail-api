class TrackingController < ApplicationController
  skip_before_action :authenticate_request! # Tracking does not require authentication
  skip_before_action :verify_authenticity_token # CSRF token is not needed for tracking

  def open
    sent_event = EmailEvent.find_by(id: params[:email_event_id])

    if sent_event&.sent?
      # Check if an open event already exists for this contact and campaign
      unless EmailEvent.exists?(contact_id: sent_event.contact_id, campaign_id: sent_event.campaign_id, event_type: :open)
        EmailEvent.create(
          contact_id: sent_event.contact_id,
          campaign_id: sent_event.campaign_id,
          email_template_id: sent_event.email_template_id,
          event_type: :open,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
      end
    else
      Rails.logger.warn "TrackingController#open: Sent EmailEvent with ID #{params[:email_event_id]} not found."
    end

    # Return a 1x1 transparent GIF
    send_data Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="),
              type: "image/gif",
              disposition: "inline"
  end

  def click
    email_event = EmailEvent.find_by(id: params[:email_event_id])

    if email_event && email_event.url.present? # Ensure it's a click event with a URL
      # Log the click event
      email_event.update(
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        event_type: :click # Ensure event_type is click
      )
      redirect_to email_event.url, allow_other_host: true
    elsif email_event.nil?
      Rails.logger.warn "TrackingController#click: EmailEvent with ID #{params[:email_event_id]} not found."
      head :not_found
    elsif !email_event.url.present?
      Rails.logger.warn "TrackingController#click: EmailEvent with ID #{params[:email_event_id]} has no URL to redirect to."
      head :bad_request
    end
  end
end
