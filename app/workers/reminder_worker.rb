class ReminderWorker
  include Sidekiq::Worker

  def perform(employee_id)
    logger.info "Sending Onboarding Reminder Email"

    employee = Employee.find employee_id
    manager = employee.manager
    mailer = ManagerMailer.reminder(manager, employee) if manager.present?

    mailer.deliver_now if mailer.present?

    logger.info "Sent to #{manager.email} for #{employee.cn}"
  end
end
