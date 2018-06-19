class ManagerMailer < ApplicationMailer
  def permissions(kind, manager, employee, opts={})
    @kind = kind
    @manager = manager
    @employee = employee
    if opts[:event_id]
      @event = AdpEvent.find(opts[:event_id])
    end
    attachments.inline['techtable.png'] = File.read(Rails.root.join('app/assets/images/techtable.png'))
    mail(to: @manager.email, subject: "IMMEDIATE ACTION REQUIRED: Employee Event Form for #{employee.first_name} #{employee.last_name}")
  end

  def reminder(manager, employee, level)
    @manager = manager
    @employee = employee
    @level = level
    attachments.inline['techtable.png'] = File.read(Rails.root.join('app/assets/images/techtable.png'))
    mail(to: @manager.email, subject: "Urgent: Mezzo Onboarding Form Due Tomorrow for #{employee.first_name} #{employee.last_name}")
  end
end
