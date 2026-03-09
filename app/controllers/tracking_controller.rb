class TrackingController < ApplicationController
  skip_before_action :authenticate_request!, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  def open
    sent_event = EmailEvent.find_by(id: params[:email_event_id])

    if sent_event
      # Use a simpler and more reliable way to check for unique opens per sent email
      already_opened = EmailEvent.where(event_type: :open, details: "sent_event_id:#{sent_event.id}").exists?

      unless already_opened
        EmailEvent.create!(
          contact_id: sent_event.contact_id,
          campaign_id: sent_event.campaign_id,
          email_template_id: sent_event.email_template_id,
          event_type: :open,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          details: "sent_event_id:#{sent_event.id}"
        )
        Rails.logger.info "[TRACKING] Open recorded for event #{sent_event.id}"
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
    original_event = EmailEvent.find_by(id: params[:email_event_id])
    url = params[:url] || original_event&.url

    if original_event && url.present?
      # Create a REAL click event
      # If original_event is a 'sent' event, we use its context
      # If it's a 'click' event (placeholder), we also use its context
      EmailEvent.create!(
        contact_id: original_event.contact_id,
        campaign_id: original_event.campaign_id,
        email_template_id: original_event.email_template_id,
        event_type: :click,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        url: url,
        details: "original_event_id:#{original_event.id}"
      )

      redirect_to url, allow_other_host: true
    elsif original_event.nil?
      Rails.logger.warn "TrackingController#click: EmailEvent with ID #{params[:email_event_id]} not found."
      head :not_found
    elsif !url.present?
      Rails.logger.warn "TrackingController#click: EmailEvent with ID #{params[:email_event_id]} has no URL to redirect to."
      head :bad_request
    end
  end
end
