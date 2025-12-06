class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("DEFAULT_FROM_EMAIL", "projecttravelplanner@gmail.com")
  layout "mailer"
end