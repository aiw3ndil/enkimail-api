require 'erb'
require 'nokogiri' # Require Nokogiri
require 'ostruct'

class UserMailer < ApplicationMailer
  include Rails.application.routes.url_helpers # For track_open_url and track_click_url

  def export_contacts_email(user, csv_data)
      attachments['contacts.csv'] = { mime_type: 'text/csv', content: csv_data }
      mail(to: user.email, subject: 'Your EnkiMail Contacts Export') do |format|
        format.html { render html: "<h1>Your contacts export is ready</h1><p>Please find the CSV file attached.</p>".html_safe }
        format.text { render plain: "Your contacts export is ready. Please find the CSV file attached." }
      end
  end


  def send_generic_email(to, template_name, contact_id, data = {}, campaign_id = nil, email_template_id = nil)
    puts "Data in send_generic_email: #{data.inspect}"
    template = EmailTemplate.find_by!(name: template_name)
    contact = Contact.find(contact_id) # Ensure contact exists

    # Render subject with ERB
    rendered_subject = render_erb_string(template.subject, data)

    # Render HTML body with ERB
    html_body_content = render_erb_string(template.body, data)
    
    # Render plain text body with ERB (if available)
    plain_text_body_content = template.plain_text_body ? render_erb_string(template.plain_text_body, data) : nil

    # --- Tracking Logic ---
    # 1. Sent Event & Open Tracking Pixel
    sent_event = EmailEvent.create!(
      event_type: :sent,
      contact_id: contact.id,
      campaign_id: campaign_id,
      email_template_id: email_template_id
    )
    tracking_pixel = "<img src='#{track_open_url(email_event_id: sent_event.id, host: Rails.application.config.action_mailer.default_url_options[:host], port: Rails.application.config.action_mailer.default_url_options[:port])}' width='1' height='1' alt=''>"
    html_body_content = html_body_content.gsub(/<\/body>/i, "#{tracking_pixel}</body>")

    # 2. Click Tracking Link Rewriting
    doc = Nokogiri::HTML(html_body_content)
    doc.css('a').each do |link|
      original_url = link['href']
      next unless original_url.present? && original_url.start_with?('http')
      click_event = EmailEvent.create!(
        event_type: :click,
        contact_id: contact.id,
        campaign_id: campaign_id,
        email_template_id: email_template_id,
        url: original_url
      )
      link['href'] = track_click_url(email_event_id: click_event.id, host: Rails.application.config.action_mailer.default_url_options[:host], port: Rails.application.config.action_mailer.default_url_options[:port])
    end
    html_body_content = doc.to_html
    # --- End Tracking Logic ---

    mail(to: to, subject: rendered_subject) do |format|
      format.html { render html: html_body_content.html_safe }
      format.text { render plain: plain_text_body_content || html_body_content } # Fallback to HTML body if no plain text
    end
  end

  private

  def render_erb_string(template_string, data)
    ERB.new(template_string).result(OpenStruct.new(data).instance_eval { binding })
  end
end
