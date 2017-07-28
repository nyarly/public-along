class AuditService

  def check_for_missed_terminations
    audit = []

    # scenario: worker has termination date in past but is still active
    missed_offboards = Employee.where('termination_date < ? AND status LIKE ?', 2.days.ago, "Active").to_a
    # scenario: worker has not been updated in adp sync recently and is active
    missed_terminations = Employee.where('updated_at < ? AND status LIKE ?', 2.days.ago, "Active").to_a
    # scenario: worker's contract has ended and they were not given a termination date
    contract_ended = Employee.where('contract_end_date < ? AND status LIKE ? AND termination_date IS NULL', 2.days.ago, "Active").to_a

    employees_to_audit = missed_offboards + missed_terminations + contract_ended

    employees_to_audit.uniq.each do |employee|
      adp_status = get_adp_status(employee)
      employee_hash = generate_employee_hash(employee, {'adp_status' => adp_status})
      audit << employee_hash
    end unless employees_to_audit.empty?

    audit
  end

  def confirm_ad_deactivation
    audit = []
    terminated_employees = Employee.where(status: "Terminated")
    ads = ActiveDirectoryService.new

    terminated_employees.each do |t|
      ad_entry = ads.find_entry("sAMAccountName", t.sam_account_name).first

      if ad_entry.present?
        ldap_dn = ad_entry[:dn][0].downcase
        usr_acct_ctrl = ad_entry[:useraccountcontrol][0]

        if ldap_dn != t.dn.downcase and usr_acct_ctrl != "514"
          employee_hash = generate_employee_hash(t, {'ldap_dn'=>ldap_dn})
          audit << employee_hash
        end
      end
    end

    audit
  end

  private

  def get_adp_status(employee)
    status = "not found"
    adp = AdpService::Base.new
    json = adp.worker("/#{employee.adp_assoc_oid}")

    if json["workers"].present?
      status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")
    end

    status
  end

  def generate_employee_hash(employee, opts={})
    employee_record = {}

    employee_record['name'] = employee.cn
    employee_record['department'] = employee.department.name
    employee_record['location'] = employee.location.name
    employee_record['job_title'] = employee.job_title.name
    employee_record['manager'] = employee.manager_id.present? ? "#{employee.manager.first_name} #{employee.manager.last_name}" : ""
    employee_record['mezzo_status'] = employee.status
    employee_record['termination_date'] = employee.termination_date.present? ? employee.termination_date : ""
    employee_record['contract_end_date'] = employee.contract_end_date.present? ? employee.contract_end_date : ""
    opts.each do |k,v|
      employee_record[k] = v
    end unless opts.empty?

    employee_record
  end

end
