class ContractorWorker
  include Sidekiq::Worker

  def perform(employee_id)
    e = Employee.find(employee_id)
    puts e
  end
end
