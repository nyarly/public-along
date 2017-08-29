class JobChangeWorker
  include Sidekiq::Worker

  def perform(emp_transaction_id)
    emp_transaction = EmpTransaction.find emp_transaction_id
    sas = SecAccessService.new(emp_transaction)
    sas.apply_ad_permissions
  end
end
