class TechTableMailer < ApplicationMailer
  default from: 'no-reply@opentable.com'
  default to: 'techtable@opentable.com'

  def alert_email(message)
    @message = message
    mail(subject: "ALERT: Mezzo Error")
  end

  def onboarding_email(emp_transaction, employee)
    @emp_transaction = emp_transaction
    @employee = employee
    @manager = User.find(@emp_transaction.user_id)
    mail(subject: "ALERT: Onboarding Request")
  end
end
