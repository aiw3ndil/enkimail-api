require 'erb'
require 'nokogiri' # Require Nokogiri
require 'ostruct'

class UserMailer < ApplicationMailer
  include TrackingConcern

  def export_contacts_email(user, csv_data)
      attachments['contacts.csv'] = { mime_type: 'text/csv', content: csv_data }
      mail(to: user.email, subject: 'Your EnkiMail Contacts Export') do |format|
        format.html { render html: "<h1>Your contacts export is ready</h1><p>Please find the CSV file attached.</p>".html_safe }
        format.text { render plain: "Your contacts export is ready. Please find the CSV file attached." }
      end
  end

  def password_reset_email(user)
    @user = user
    # Typically you would point this to your frontend URL
    # For now we assume a standard route, but frontend should handle this
    @url = "#{ENV['FRONTEND_URL'] || 'http://localhost:3000'}/reset-password?token=#{@user.reset_password_token}"
    
    mail(to: @user.email, subject: 'Reset your EnkiMail password') do |format|
      format.html { render html: "<h1>Password Reset</h1><p>Click the link below to reset your password:</p><a href='#{@url}'>Reset Password</a><p>This link will expire in 2 hours.</p>".html_safe }
      format.text { render plain: "Password Reset. Click the link below to reset your password: #{@url}. This link will expire in 2 hours." }
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
    html_body_content = add_tracking_to_html(html_body_content, contact_id, campaign_id, email_template_id)
    # --- End Tracking Logic ---

    mail(to: to, subject: rendered_subject) do |format|
      format.html { render html: html_body_content.html_safe }
      format.text { render plain: plain_text_body_content || html_body_content } # Fallback to HTML body if no plain text
    end
  end

  private

  def render_erb_string(template_string, data)
    # Support {{variable}} by converting it to <%= variable %> before ERB processing
    processed_template = template_string.gsub(/\{\{\s*(\w+)\s*\}\}/, '<%= \1 %>')
    ERB.new(processed_template).result(OpenStruct.new(data).instance_eval { binding })
  end
end
