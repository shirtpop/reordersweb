class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.smtp[:from_email]
  layout "mailer"
end
