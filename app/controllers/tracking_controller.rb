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
    sent_event = EmailEvent.find_by(id: params[:email_event_id])

    if sent_event && sent_event.url.present?
      # Create a new click event linked to the same contact/campaign/template
      EmailEvent.create(
        contact_id: sent_event.contact_id,
        campaign_id: sent_event.campaign_id,
        email_template_id: sent_event.email_template_id,
        event_type: :click,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        url: sent_event.url # Optional: store the clicked URL for reference
      )

      redirect_to sent_event.url, allow_other_host: true
    elsif sent_event.nil?
      Rails.logger.warn "TrackingController#click: EmailEvent with ID #{params[:email_event_id]} not found."
      head :not_found
    elsif !sent_event.url.present?
      Rails.logger.warn "TrackingController#click: EmailEvent with ID #{params[:email_event_id]} has no URL to redirect to."
      head :bad_request
    end
  end
end
