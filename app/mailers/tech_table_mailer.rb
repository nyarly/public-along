class TechTableMailer < ApplicationMailer
  default to: [Rails.application.secrets.tt_email]

  def alert_email(message)
    @message = message
    mail(subject: "ALERT: Mezzo Error")
  end

  def permissions(emp_transaction, employee)
    @emp_transaction = emp_transaction
    @employee = employee
    @manager = User.find(@emp_transaction.user_id)
    mail(subject: "IMMEDIATE ACTION REQUIRED: #{emp_transaction.kind} request for #{employee.first_name} #{employee.last_name}")
  end
end
