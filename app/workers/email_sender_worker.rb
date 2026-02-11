class EmailSenderWorker
  include Sidekiq::Worker

  def perform(to, template_name, data)
    UserMailer.send_generic_email(to, template_name, data).deliver_now
  end
end
