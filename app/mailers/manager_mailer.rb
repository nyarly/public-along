class ManagerMailer < ApplicationMailer
  def permissions(manager, employee, kind)
    @manager = manager
    @employee = employee
    @kind = kind
    attachments.inline['techtable.png'] = File.read(Rails.root.join('app/assets/images/techtable.png'))
    mail(to: @manager.email, subject: "IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
  end
end
