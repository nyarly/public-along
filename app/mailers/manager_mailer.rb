class ManagerMailer < ApplicationMailer
  def permissions(manager, employee, kind)
    @manager = manager
    @employee = employee
    @kind = kind
    mail(to: @manager.email, subject: "IMMEDIATE ACTION REQUIRED: #{kind} forms for #{employee.first_name} #{employee.last_name}")
  end
end
