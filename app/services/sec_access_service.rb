class SecAccessService
  attr_accessor :emp_transaction, :add_sec_groups, :revoke_sec_groups
  attr_accessor :results, :handle_results

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
    # scan for failed transactions
    return true if !@results.include? "Failed"
    alert_tech_table
    # log results
  end

  def alert_tech_table
    Error::ErrorMailer.new("TechTableMailer", composed_subject, composed_message)
  end

  def composed_subject
    "Mezzo: Failed Security Access Change for #{@emloyee.cn}"
  end

  def composed_message
    "Mezzo received a request to add and/or remove #{@employee.cn} from security groups in Active Directory.\nOne or more of these transactions have failed. Please reference the results of the transaction below:\n#{@results}"
  end
end
