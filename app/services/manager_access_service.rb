class ManagerAccessService
  def initialize(employee)
    @employee = employee
    @manager_sec_profile = SecurityProfile.find_by(name: "Basic Manager")
  end

  def process!
    if needs_manager_permissions?
      begin
      ensure
        create_emp_transaction
        create_emp_sec_profile
        add_manager_sec_group
      end
    end
    @employee.security_profiles
  end

  private

  def needs_manager_permissions?
    return false if @employee.current_profile.management_position != true
    return false if @employee.security_profiles.include? @manager_sec_profile
    true
  end

  def create_emp_transaction
    @emp_transaction = EmpTransaction.new(
      kind: "Service",
      notes: "Manager permissions added by Mezzo",
      employee_id: @employee.id
    ).tap do |emp_transaction|
      emp_transaction.save!
    end
  end

  def create_emp_sec_profile
    @emp_sec_profile = EmpSecProfile.new(
      emp_transaction_id: @emp_transaction.id,
      security_profile_id: @manager_sec_profile.id
    ).tap do |emp_sec_profile|
      emp_sec_profile.save!
    end
  end

  def add_manager_sec_group
    return false if @emp_transaction.emp_sec_profiles.count == 0
    SecAccessService.new(@emp_transaction).apply_ad_permissions
  end
end
