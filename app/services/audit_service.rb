require 'csv'

class AuditService

  # scenario: worker has termination date in past but is still active
  # scenario: worker has not been updated in adp sync recently and is active
  # scenario: worker's contract has ended and they were not given a termination date
  def missed_terminations
    audit = []
    missed_offboards = Employee.where('termination_date < ? AND status LIKE ?', 2.days.ago, "active").to_a
    missed_terminations = Employee.where('updated_at < ? AND status LIKE ?', 2.days.ago, "active").to_a
    contract_ended = Employee.where('contract_end_date < ? AND status LIKE ? AND termination_date IS NULL', 2.days.ago, "active").to_a

    employees_to_audit = missed_offboards + missed_terminations + contract_ended
    employees_to_audit.uniq.each do |employee|
      data = check_adp(employee)
      employee_hash = generate_employee_hash(employee, data)
      audit << employee_hash
    end unless employees_to_audit.empty?
    audit
  end

  def ad_deactivation
    audit = []
    terminated_employees = Employee.where(status: "terminated")
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

  def generate_csv(data)
    CSV.generate(headers: true, col_sep: ",") do |csv|
      csv << data.first.keys
      data.each do |e|
        row = []
        e.each do |k,v|
          row << v
        end
        csv << row
      end
    end
  end

  private

  def check_adp(e)
    data = {}
    adp = AdpService::Base.new
    json = adp.worker("/#{e.adp_assoc_oid}")
    if json["workers"].present?
      data[:adp_status] = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")
      data[:adp_term_date] = json.dig("workers", 0, "workerDates", "terminationDate")
    end
    data
  end

  def generate_employee_hash(e, opts={})
    h = {}
    h[:name] = e.cn
    h[:job_title] = e.job_title.name
    h[:department] = e.department.name
    h[:location] = e.location.name
    h[:manager] = e.manager_id.present? ? "#{e.manager.first_name} #{e.manager.last_name}" : ""
    h[:mezzo_status] = e.status
    h[:mezzo_term_date] = e.termination_date.present? ? e.termination_date.strftime("%Y-%m-%d") : ""
    h[:contract_end_date] = e.contract_end_date.present? ? e.contract_end_date.strftime("%Y-%m-%d") : ""
    opts.each do |k,v|
      h[k] = v
    end unless opts.empty?
    h
  end

end
