class SecurityAccessForm
  include Virtus.model

  attr_accessor :emp_transaction
  attr_accessor :employee

  def save
    TechTableWorker.perform_async(:permissions, emp_transaction.id)
  end
end
