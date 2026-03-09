require 'nokogiri'

module TrackingConcern
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def add_tracking_to_html(html_body, contact_id, campaign_id = nil, email_template_id = nil)
    # 1. Sent Event (Always create this first!)
    sent_event = EmailEvent.create!(
      event_type: :sent,
      contact_id: contact_id,
      campaign_id: campaign_id,
      email_template_id: email_template_id
    )

    return html_body unless html_body.present?

    # 2. Open Tracking Pixel
    tracking_pixel = "<img src='#{track_open_url(email_event_id: sent_event.id, host: tracking_host, port: tracking_port)}' width='1' height='1' alt=''>"
    html_with_pixel = html_body.gsub(/<\/body>/i, "#{tracking_pixel}</body>")
    
    # If no </body> tag, just append it
    unless html_with_pixel.include?(tracking_pixel)
      html_with_pixel = "#{html_with_pixel}#{tracking_pixel}"
    end

    # 2. Click Tracking Link Rewriting
    doc = Nokogiri::HTML(html_with_pixel)
    doc.css('a').each do |link|
      original_url = link['href']
      next unless original_url.present? && original_url.start_with?('http')
      
      # We don't create an event here anymore, we pass the info in the URL
      # We use the sent_event.id to identify the context (contact/campaign)
      link['href'] = track_click_url(email_event_id: sent_event.id, url: original_url, host: tracking_host, port: tracking_port)
    end

    doc.to_html
  end

  private

  def tracking_host
    Rails.application.config.action_mailer.default_url_options[:host] || 'localhost'
  end

  def tracking_port
    Rails.application.config.action_mailer.default_url_options[:port]
  end
end
