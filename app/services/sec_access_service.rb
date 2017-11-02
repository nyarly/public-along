class SecAccessService
  # attr_accessor :emp_transaction, :add_sec_groups, :revoke_sec_groups
  attr_accessor :results, :failures

  def initialize(emp_transaction)
    @emp_transaction = emp_transaction
    @add_sec_groups = []
    @revoke_sec_groups = []
    @results = {}
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
    ads = ActiveDirectoryService.new

    @results[:added] = @add_sec_groups.map { |sg| ads.modify_sec_groups("add", sg, @employee) unless sg.blank? } unless @add_sec_groups.blank?
    @results[:revoked] = @revoke_sec_groups.map { |sg| ads.modify_sec_groups("delete", sg, @employee) unless sg.blank? } unless @revoke_sec_groups.blank?
    @results
  end

  def handle_results
    scan_for_failed_ldap_transactions
    alert_tech_table if @failures.present?
    @results
  end

  def scan_for_failed_ldap_transactions
    @failures = []
    @results[:added][0].each do |k, v|
      v.scan("Failure") { |e| @failures << k + " could not be added. " + v }
    end
    @results[:revoked][0].each do |k, v|
      v.scan("Failure") { |e| @failures << k + " could not be removed. " + v }
    end
    @failures
  end

  def alert_tech_table
    Errors::ErrorMailer.new(TechTableMailer, composed_subject, composed_message, @failures).send_message
  end

  def composed_subject
    "Failed Security Access Change for #{@emp_transaction.employee.cn}"
  end

  def composed_message
    "Mezzo received a request to add and/or remove #{@emp_transaction.employee.cn} from security groups in Active Directory.\nOne or more of these transactions have failed. Please review the results of the transaction below:"
  end
end
