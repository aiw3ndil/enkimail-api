require 'erb'

class UserMailer < ApplicationMailer
  def send_generic_email(to, template_name, data = {})
    template = EmailTemplate.find_by!(name: template_name)

    # Render subject with ERB
    rendered_subject = ERB.new(template.subject).result_with_hash(data)

    # Render HTML body with ERB
    @body = ERB.new(template.body).result_with_hash(data)

    # Render plain text body with ERB (if available)
    @plain_text_body = template.plain_text_body ? ERB.new(template.plain_text_body).result_with_hash(data) : nil

    mail(to: to, subject: rendered_subject) do |format|
      format.html { render html: @body.html_safe }
      format.text { render plain: @plain_text_body || @body } # Fallback to HTML body if no plain text
    end
  end
end
