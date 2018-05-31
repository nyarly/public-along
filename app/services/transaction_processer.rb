# Responsible for processing the results of an employee transaction
class TransactionProcesser
  attr_reader :emp_transaction, :employee

  def initialize(emp_transaction)
    @emp_transaction = emp_transaction
    @employee = @emp_transaction.employee
  end

  def call
    return true if emp_transaction.offboarding?
    return onboard if emp_transaction.onboarding?
    return job_change if emp_transaction.job_change?
    update_security_profiles
    send_email
  end

  private

  def job_change
    alternative_onboard
  end

  def onboard
    return standard_onboard if employee.pending?
    alternative_onboard
  end

  def alternative_onboard
    return new_record_onboard if employee.created?
    re_onboard
  end

  def new_record_onboard
    employee.hire!
    EmployeeService::Onboard.new(employee).new_worker
    TechTableWorker.perform_async(:onboard_instructions, emp_transaction.id)
  end

  def re_onboard
    employee.hire!
    EmployeeService::Onboard.new(employee).re_onboard
    TechTableWorker.perform_async(:onboard_instructions, emp_transaction.id)
  end

  def standard_onboard
    update_security_profiles
    TechTableWorker.perform_async(:onboard_instructions, emp_transaction.id)
  end

  def update_security_profiles
    SecAccessService.new(emp_transaction).apply_ad_permissions
  end

  def send_email
    TechTableWorker.perform_async(:permissions, emp_transaction.id)
  end
end
