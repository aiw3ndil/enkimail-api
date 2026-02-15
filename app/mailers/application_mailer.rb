class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@enkimail.com"
  layout "mailer"
end
