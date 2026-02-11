class TrackingController < ApplicationController
  skip_before_action :authenticate_request! # Tracking does not require authentication
  skip_before_action :verify_authenticity_token # CSRF token is not needed for tracking

  def open
    # We expect params[:email_event_id] to be the ID of the EmailEvent for opening
    email_event = EmailEvent.find_by(id: params[:email_event_id])

    if email_event # Check if the event exists
      # Update only if it's the first open or we want to log multiple opens
      # For simplicity, we'll update only if it's an open event
      # We could also track multiple opens by creating a new EmailEvent if the original event represents the 'initial send'
      unless email_event.open? # Only update if the event hasn't been marked as opened yet
        email_event.update(
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          event_type: :open,
          # Optionally update timestamp, but default is already set to NOW() on create
        )
      end
    else
      Rails.logger.warn "TrackingController#open: EmailEvent with ID #{params[:email_event_id]} not found."
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
