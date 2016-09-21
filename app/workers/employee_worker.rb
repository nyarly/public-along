class EmployeeWorker
  include Sidekiq::Worker

  def perform(action, employee_id)
    @employee = Employee.find(employee_id)
    @manager = Employee.find_by(employee_id: @employee.manager_id)

    if action == "onboard"
      @mailer = ManagerMailer.permissions(@manager, @employee, "Onboarding")
    elsif action == "job_change"
      @mailer = ManagerMailer.permissions(@manager, @employee, "Security Access")
    end if @manager.present?

    @mailer.deliver_now if @mailer.present?
  end
end
