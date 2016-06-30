class TechTableMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'

  def alert_email(message)
    @email = "techtable@opentable.com"
    @message = message
    mail(to: @email, subject: "ALERT: Mezzo Error")
  end
end
