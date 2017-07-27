class AuditService

  def check_for_missed_terminations
    employees_to_audit = []

    # scenario: worker has termination date in past but is still active
    missed_offboards = Employee.where('termination_date < ? AND status LIKE ?', 2.days.ago, "Active")
    # scenario: worker has not been updated in adp sync recently and is active
    missed_terminations = Employee.where('updated_at < ? AND status LIKE ?', 2.days.ago, "Active")
    # scenario: worker's contract has ended and they were not given a termination date
    contract_ended = Employee.where('contract_end_date < ? AND status LIKE ? AND termination_date IS NULL', 2.days.ago, "Active")



    missed_offboards.each do |employee|
      employee_record = {}
      adp_status = get_adp_status(employee)

      if status == "Terminated"
        terminate(employee)
      end

      employee_record['name'] = employee.cn
      employee_record['department'] = employee.department.name
      employee_record['location'] = employee.location.name
      employee_record['job_title'] = employee.job_title.name
      employee_record['manager'] = employee.manager_id.present? ? "#{employee.manager.first_name} #{employee.manager.last_name}" : ""
      employee_record['adp_status'] = adp_status
      employee_record['mezzo_status'] = employee.status
      employee_record['termination_date'] = employee.termination_date.present? ? employee.termination_date : ""
      employee_record['contract_end_date'] = employee.contract_end_date.present? ? employee.contract_end_date : ""

      employees_to_audit << employee_record
    end

    employees_to_audit
  end


  # check that terminated workers are disabled in active directory

  # check for workers with contract end date in past but no termination date
    # check disabled and email p&c

  # check for workers on leave
    # inactive workers should have leave start date
    # inactive workers should be disabled in active directory


  def get_adp_status(employee)
    status = "Inconclusive"

    adp = AdpService::Base.new
    json = adp.worker("/#{employee.adp_assoc_oid}")

    if json["workers"].present?
      w_hash = workers[0]
      status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")
    end

    status
  end

  def terminate(employee)
    ads = ActiveDirectoryService.new
    ads.deactivate([e])

    TechTableMailer.offboard_notice(employee).deliver_now

    off = OffboardingService.new
    off.offboard([e])
  end

end
