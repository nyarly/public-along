class ManagerMailer < ApplicationMailer
  def permissions(manager, employee)
    @manager = manager
    @employee = employee
    mail(to: @manager.email, subject: "IMMEDIATE ACTION REQUIRED: Onboarding forms for new hire - #{employee.first_name} #{employee.last_name}")
  end
end
