class SecAccessService
  attr_accessor :emp_transaction, :ad_sec_groups

  def initialize(emp_transaction)
    @emp_transaction = emp_transaction
    @ad_sec_groups = []
    @employee = Employee.find(@emp_transaction.emp_sec_profiles.first.employee_id)
  end

  def apply_ad_permissions
    if @emp_transaction.save
      collect_groups

      if @ad_sec_groups.blank?
        return true
      else
        add_employee_to_groups
      end

      TechTableMailer.onboarding_email(@emp_transaction, @employee).deliver_now
    end
  end

  def collect_groups
    @emp_transaction.security_profiles.each do |sp|
      sp.access_levels.each do |al|
        @ad_sec_groups << al.ad_security_group
      end
    end
  end

  def add_employee_to_groups
    @ad_sec_groups.each do |asg|
      ads = ActiveDirectoryService.new
      ads.add_to_sec_group(asg, @employee) unless asg.blank?
    end
  end
end
