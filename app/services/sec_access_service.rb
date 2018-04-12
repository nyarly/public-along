class SecAccessService
  attr_accessor :results, :failures

  def initialize(emp_transaction)
    @ads = ActiveDirectoryService.new
    @emp_transaction = emp_transaction
    @add_sec_groups = []
    @revoke_sec_groups = []
    @results = []
    @failures = []
  end

  def apply_ad_permissions
    collect_groups
    set_employee
    add_or_remove_employee_from_groups
    handle_results
  end

  private

  def set_employee
    emp_id = @emp_transaction.employee_id
    @employee = Employee.find(emp_id) if emp_id
  end

  def collect_groups
    @add_sec_groups = @emp_transaction.security_profiles.flat_map {
                        |s| s.access_levels.map {
                          |a| a.ad_security_group
                        }
                      }
    @revoke_sec_groups = @emp_transaction.revoked_security_profiles.flat_map {
                           |s| s.access_levels.map {
                             |a| a.ad_security_group
                           }
                         }
  end

  def add_or_remove_employee_from_groups
    @revoke_sec_groups.each do |sg|
      @results << @ads.modify_sec_group("delete", sg, @employee) unless sg.blank?
    end unless @revoke_sec_groups.blank?

    @add_sec_groups.each do |sg|
      @results << @ads.modify_sec_group("add", sg, @employee) unless sg.blank?
    end unless @add_sec_groups.blank?
    @results
  end

  def handle_results
    scan_for_failed_ldap_transactions
    alert_tech_table if @failures.present?
    @results
  end

  def scan_for_failed_ldap_transactions
    failed_ldap_transactions = @ads.scan_for_failed_ldap_transactions(@results)
    @failures << failed_ldap_transactions if failed_ldap_transactions.present?
    @failures = @failures.flatten
  end

  def alert_tech_table
    @ads.sec_access_update_failure(@employee, @failures)
  end
end
