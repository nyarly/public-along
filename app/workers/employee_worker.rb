class EmployeeWorker
  include Sidekiq::Worker

  def perform(action, employee_id)
    @employee = Employee.find(employee_id)
    @manager = Employee.find_by_employee_id(@employee.manager_id)

    @mailer = ManagerMailer.permissions(@manager, @employee, action) if @manager.present?
    @mailer.deliver_now if @mailer.present?
  end
end
