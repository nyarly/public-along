class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@opentable.com"
  layout 'mailer'
end
