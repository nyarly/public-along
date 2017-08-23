class EmployeeWorker
  include Sidekiq::Worker

  def perform(action, opts={})
    if opts[:employee_id].present?
      @employee = Employee.find(opts[:employee_id])
      @manager = Employee.find_by_employee_id(@employee.manager_id)
      @mailer = ManagerMailer.permissions(action, @manager, @employee) if @manager.present?
    elsif opts[:event_id].present?
      profiler = EmployeeProfile.new
      @event = AdpEvent.find opts[:event_id]
      @employee = profiler.build_employee(@event)
      @manager = @employee.manager
      @mailer = ManagerMailer.permissions(action, @manager, @employee, {:event => @event})
    end

    @mailer.deliver_now if @mailer.present?
  end
end
