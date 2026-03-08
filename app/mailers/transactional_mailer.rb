class TransactionalMailer < ApplicationMailer
  def send_email(to:, subject:, body: nil, html_body: nil, from: nil)
    @body = body
    @html_body = html_body
    
    from_address = from || default_params[:from]

    mail(to: to, subject: subject, from: from_address) do |format|
      if @html_body.present?
        format.html { render inline: @html_body, layout: false }
        format.text { render plain: @body } if @body.present?
      else
        format.text { render plain: @body }
      end
    end
  end
end
