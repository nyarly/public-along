class UpdateEmailWorker
  include Sidekiq::Worker

  def perform(employee_id)
    employee = Employee.find employee_id
    worker = AdpService::Worker.new
    worker.update_worker_email(employee)
  end
end
