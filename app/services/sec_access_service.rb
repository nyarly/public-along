class SecAccessService
  attr_accessor :emp_transaction, :add_sec_groups, :revoke_sec_groups

  def initialize(emp_transaction)
    @emp_transaction = emp_transaction
    @add_sec_groups = []
    @revoke_sec_groups = []
    set_employee
  end

  def apply_ad_permissions
    if @emp_transaction.save
      collect_groups
      add_or_remove_employee_from_groups

      TechTableMailer.onboarding_email(@emp_transaction, @employee).deliver_now
    end
  end

  def set_employee
    if @emp_transaction.emp_sec_profiles.count > 0
      emp_id = @emp_transaction.emp_sec_profiles.first.employee_id
    elsif @emp_transaction.revoked_emp_sec_profiles.count > 0
      emp_id = @emp_transaction.revoked_emp_sec_profiles.first.employee_id
    end

    @employee = Employee.find(emp_id)
  end

  def collect_groups
    @emp_transaction.security_profiles.each do |sp|
      sp.access_levels.each do |al|
        @add_sec_groups << al.ad_security_group
      end
    end

    @emp_transaction.revoked_security_profiles.each do |sp|
      sp.access_levels.each do |al|
        @revoke_sec_groups << al.ad_security_group
      end
    end
  end

  def add_or_remove_employee_from_groups
    ads = ActiveDirectoryService.new
    @add_sec_groups.each do |sg|
      ads.add_to_sec_group(sg, @employee) unless sg.blank?
    end unless @add_sec_groups.blank?

    @revoke_sec_groups.each do |sg|
      ads.remove_from_sec_group(sg, @employee) unless sg.blank?
    end unless @revoke_sec_groups.blank?
  end
end
