class ContractorWorker
  include Sidekiq::Worker

  def perform(employee_id)
    employee = Employee.find(employee_id)
    manager = employee.manager
    if e.manager.present?
      mailer = ManagerMailer.permissions("Offboarding", manager, employee)
      mailer.deliver_now
    end
  end
end
