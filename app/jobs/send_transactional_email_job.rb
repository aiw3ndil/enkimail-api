class SendTransactionalEmailJob < ApplicationJob
  queue_as :default

  def perform(email_params)
    # email_params should be a hash with keys: 'to', 'subject', 'body', 'html_body', 'from'
    
    to = email_params['to'] || email_params[:to]
    subject = email_params['subject'] || email_params[:subject]
    body = email_params['body'] || email_params[:body]
    html_body = email_params['html_body'] || email_params[:html_body]
    from = email_params['from'] || email_params[:from]

    TransactionalMailer.send_email(
      to: to,
      subject: subject,
      body: body,
      html_body: html_body,
      from: from
    ).deliver_now
  end
end
