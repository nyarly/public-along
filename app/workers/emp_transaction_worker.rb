class EmpTransactionWorker
  include Sidekiq::Worker

  def perform(emp_transaction_id)
    transaction = EmpTransaction.find(emp_transaction_id)
    TransactionProcesser.new(transaction).call
  end
end
