class EmployeeWorker
  include Sidekiq::Worker

  def perform(action, opts={})
    logger.info "Performing onboarding manager mailer"
    logger.info action
    logger.info opts
    if opts["employee_id"].present?
      @employee = Employee.find(opts["employee_id"])
      @manager = @employee.manager
      @mailer = ManagerMailer.permissions(action, @manager, @employee) if @manager.present?
      logger.info "on hire event for @employee.cn, sending to @manager.email"
    elsif opts["event_id"].present?
      profiler = EmployeeProfile.new
      @event = AdpEvent.find(opts["event_id"])
      @employee = profiler.build_employee(@event)
      @manager = @employee.manager
      @mailer = ManagerMailer.permissions(action, @manager, @employee, event_id: @event.id) if @manager.present?
      logger.info "on rehire/job change event for @employee.cn, sending to @manager.email"
    end

    @mailer.deliver_now if @mailer.present?
  end
end
