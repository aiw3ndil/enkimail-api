class TransactionalMailer < ApplicationMailer
  def send_email(to:, subject:, body: nil, html_body: nil, from: nil)
    @body = body
    @html_body = html_body
    
    mail(
      to: to,
      subject: subject,
      from: from || default_params[:from]
    ) do |format|
      format.text { render plain: @body } if @body.present?
      format.html { render html: @html_body.html_safe } if @html_body.present?
    end
  end
end
