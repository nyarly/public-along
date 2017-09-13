class ReminderWorker
  include Sidekiq::Worker

  def perform(opts={})
    logger.info "Sending Onboarding Reminder Email"

    if opts["employee_id"].present?
      employee = Employee.find(opts["employee_id"])
      manager = employee.manager
      mailer = ManagerMailer.reminder(manager, employee) if manager.present?
    elsif["event_id"].present?
      event = AdpEvent.find(opts["event_id"])
      profiler = EmployeeProfile.new
      employee = profiler.build_employee(event)
      manager = employee.manager
      mailer = ManagerMailer.reminder(manager, employee) if manager.present?
    end

    mailer.deliver_now if mailer.present?

    logger.info "Sent to #{manager.email} for #{employee.cn}"
  end
end
