require 'erb'
require 'nokogiri' # Require Nokogiri

class UserMailer < ApplicationMailer
  include Rails.application.routes.url_helpers # For track_open_url and track_click_url

  def send_generic_email(to, template_name, data = {}, contact_id, campaign_id = nil, email_template_id = nil)
    template = EmailTemplate.find_by!(name: template_name)
    contact = Contact.find(contact_id) # Ensure contact exists

    # Render subject with ERB
    rendered_subject = ERB.new(template.subject).result_with_hash(data)

    # Render HTML body with ERB
    html_body_content = ERB.new(template.body).result_with_hash(data)
    
    # Render plain text body with ERB (if available)
    plain_text_body_content = template.plain_text_body ? ERB.new(template.plain_text_body).result_with_hash(data) : nil

    # --- Tracking Logic ---

    # 1. Open Tracking Pixel
    # Create an EmailEvent for opening (type: open)
    open_event = EmailEvent.create!(
      event_type: :open,
      contact_id: contact.id,
      campaign_id: campaign_id,
      email_template_id: email_template_id
    )
    # Inject tracking pixel into HTML body
    tracking_pixel = "<img src='#{track_open_url(email_event_id: open_event.id, host: Rails.application.config.action_mailer.default_url_options[:host], port: Rails.application.config.action_mailer.default_url_options[:port])}' width='1' height='1' alt=''>"
    html_body_content = html_body_content.gsub(/<\/body>/i, "#{tracking_pixel}</body>") # Inject before </body>

    # 2. Click Tracking Link Rewriting
    doc = Nokogiri::HTML(html_body_content)
    doc.css('a').each do |link|
      original_url = link['href']
      next unless original_url.present? && original_url.start_with?('http') # Only track http(s) links

      # Create an EmailEvent for clicking (type: click)
      click_event = EmailEvent.create!(
        event_type: :click,
        contact_id: contact.id,
        campaign_id: campaign_id,
        email_template_id: email_template_id,
        url: original_url
      )
      # Rewrite the link to point to our click tracking endpoint
      link['href'] = track_click_url(email_event_id: click_event.id, host: Rails.application.config.action_mailer.default_url_options[:host], port: Rails.application.config.action_mailer.default_url_options[:port])
    end
    html_body_content = doc.to_html

    # --- End Tracking Logic ---

    mail(to: to, subject: rendered_subject) do |format|
      format.html { render html: html_body_content.html_safe }
      format.text { render plain: plain_text_body_content || html_body_content } # Fallback to HTML body if no plain text
    end
  end
end
