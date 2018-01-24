class TechTableWorker
  include Sidekiq::Worker

  def perform(mailer_method, emp_transaction_id)
    transaction = EmpTransaction.find(emp_transaction_id)
    TechTableMailer.send(mailer_method, transaction).deliver_now
  end
end
