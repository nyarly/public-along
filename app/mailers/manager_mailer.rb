class ManagerMailer < ApplicationMailer
  def permissions(kind, manager, employee, opts={})
    @kind = kind
    @manager = manager
    @employee = employee
    if opts[:event]
      @event = opts[:event]
    end
    attachments.inline['techtable.png'] = File.read(Rails.root.join('app/assets/images/techtable.png'))
    mail(to: @manager.email, subject: "IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
  end
end
