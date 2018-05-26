class SendHrTempExpirationNotice
  include Sidekiq::Worker

  def perform(employee_id)
    employee = Employee.find(employee_id)
    PeopleAndCultureMailer.upcoming_contract_end(contractor).deliver_now
  end
end
