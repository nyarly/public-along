class SendManagerOffboardForm
  include Sidekiq::Worker

  def perform(employee_id)
    ActiveRecord::Base.transaction do
      begin
        employee = Employee.find(employee_id)
        return true if employee.request_status != 'none'
        mailer = ManagerMailer.permissions('Offboarding', employee.manager, employee)
        mailer.deliver_now
        employee.wait!
      end
    end
  end
end
