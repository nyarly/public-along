class TechTableMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'

  def alert_email(message)
    @email = "techtable@opentable.com"
    @message = message
    mail(to: @email, subject: "ALERT: Mezzo Error")
  end

  def onboarding_email(emp_transaction, employee)
    @email = "techtable@opentable.com"
    @emp_transaction = emp_transaction
    @employee = employee
    @manager = User.find(@emp_transaction.user_id)
    mail(to: @email, subject: "ALERT: Onboarding Request")
  end
end
