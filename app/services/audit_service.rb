require 'csv'

class AuditService

  # scenario: worker has termination date in past but is still active
  # scenario: worker has not been updated in adp sync recently and is active
  # scenario: worker's contract has ended and they were not given a termination date
  def missed_terminations
    audit = []
    unless audit_list.empty?
      audit_list.each do |employee|
        data = check_adp(employee)
        employee_hash = generate_employee_hash(employee, data)
        audit << employee_hash
      end
    end
    audit
  end

  def audit_list
    Employee.where('status LIKE ?
                    AND (termination_date < ?
                    OR adp_status LIKE ?
                    OR updated_at < ?
                    OR contract_end_date < ?)',
      'active',
      1.day.ago,
      'Terminated',
      2.hours.ago,
      1.day.ago).order(:last_name)
  end

  def missed_deactivations
    audit = []

    terminated_employees.each do |t|
      ad_entry = check_active_directory(t)
      audit << generate_employee_hash(t, 'ldap_dn' => ldap_dn(ad_entry)) if ad_entry.present? && deactivated?(ad_entry, t)
    end
    audit
  end

  def generate_csv(data)
    CSV.generate(headers: true) do |csv|
      csv << data.first.keys
      data.each do |e|
        row = []
        e.each do |_, v|
          row << v
        end
        csv << row
      end
    end
  end

  private

  def terminated_employees
    Employee.where(status: 'terminated')
  end

  def ad_service
    @ad_service ||= ActiveDirectoryService.new
  end

  def check_active_directory(termed_worker)
    ad_service.find_entry('sAMAccountName', termed_worker.sam_account_name).first
  end

  def ldap_dn(ad_entry)
    ad_entry[:dn][0].downcase
  end

  def usr_acct_ctrl(ad_entry)
    ad_entry[:useraccountcontrol][0]
  end

  def deactivated?(ad_entry, worker)
    ldap_dn(ad_entry) != worker.dn.downcase || usr_acct_ctrl(ad_entry) != '514'
  end

  def check_adp(employee)
    data = {}
    adp = AdpService::Base.new
    json = adp.worker("/#{employee.adp_assoc_oid}")
    if json['workers'].present?
      data[:current_adp_status] = json.dig('workers', 0, 'workerStatus', 'statusCode', 'codeValue')
      data[:adp_term_date] = json.dig('workers', 0, 'workerDates', 'terminationDate')
    end
    data
  end

  def generate_employee_hash(employee, opts = {})
    h = {}
    h[:name] = employee.cn
    h[:job_title] = employee.job_title.name
    h[:department] = employee.department.name
    h[:location] = employee.location.name
    h[:manager] = employee.manager_id.present? ? "#{employee.manager.first_name} #{employee.manager.last_name}" : ''
    h[:status] = employee.status
    h[:adp_status] = employee.adp_status
    h[:term_date] = employee.termination_date.present? ? employee.termination_date.strftime('%Y-%m-%d') : ''
    h[:contract_end_date] = employee.contract_end_date.present? ? employee.contract_end_date.strftime('%Y-%m-%d') : ''
    h[:offboarded_at] = employee.offboarded_at.present? ? employee.offboarded_at.strftime('%Y-%m-%d') : ''
    unless opts.empty?
      opts.each do |k, v|
        h[k] = v
      end
    end
    h
  end

end
