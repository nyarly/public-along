class ManagerMailer < ApplicationMailer
  def permissions(manager, employee)
    @manager = manager
    @employee = employee
    mail(to: @manager.email, subject: "Onboarding: Set permissions for #{employee.first_name} #{employee.last_name}")
  end
end
