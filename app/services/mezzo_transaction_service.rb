class MezzoTransactionService
  def initialize(employee_id, security_profile_id)
    @employee_id = employee_id
    @security_profile_id = security_profile_id
  end

  def process!
    create_emp_transaction
    create_emp_sec_profile
    add_security_group
  end

  private

  def create_emp_transaction
    @emp_transaction = EmpTransaction.new(
      kind: 'service',
      notes: "Service transaction performed by Mezzo",
      employee_id: @employee_id
    ).tap do |emp_transaction|
      emp_transaction.save!
    end
  end

  def create_emp_sec_profile
    @emp_sec_profile = EmpSecProfile.new(
      emp_transaction_id: @emp_transaction.id,
      security_profile_id: @security_profile_id
    ).tap do |emp_sec_profile|
      emp_sec_profile.save!
    end
  end

  def add_security_group
    return false if @emp_transaction.emp_sec_profiles.count == 0
    SecAccessService.new(@emp_transaction).apply_ad_permissions
  end
end
