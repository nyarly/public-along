class EmployeeChangeWorker
  include Sidekiq::Worker

  def perform(employee_id)
    e = Employee.find employee_id
    workers = AdpService::Workers.new
    workers.look_ahead(e)
  end
end
