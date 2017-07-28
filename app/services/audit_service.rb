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
      employee_hash = generate_employee_hash(employee, adp_status)

      audit << employee_hash
    end unless employees_to_audit.empty?

    audit
  end

  def confirm_ad_deactivation
    terminated_employees = Employee.where(status: "Terminated")
    ads = ActiveDirectoryService.new

    terminated_employees.all.each do |t|
      ad_entry = ads.find_entry("sAMAccountName", e.sam_account_name).first

      if ad_entry.dn.include? "OU=Disabled Users" and ad_entry.userAccountControl == ["514"]
        # do the things
      end
    end
  end

  # check for workers with contract end date in past but no termination date
    # check disabled and email p&c

  # check for workers on leave
    # inactive workers should have leave start date
    # inactive workers should be disabled in active directory


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

  def employee_hash(employee, adp_status)
    employee_record = {}

    employee_record['name'] = employee.cn
    employee_record['department'] = employee.department.name
    employee_record['location'] = employee.location.name
    employee_record['job_title'] = employee.job_title.name
    employee_record['manager'] = employee.manager_id.present? ? "#{employee.manager.first_name} #{employee.manager.last_name}" : ""
    employee_record['adp_status'] = adp_status
    employee_record['mezzo_status'] = employee.status
    employee_record['termination_date'] = employee.termination_date.present? ? employee.termination_date : ""
    employee_record['contract_end_date'] = employee.contract_end_date.present? ? employee.contract_end_date : ""

    employee_record
  end

end
