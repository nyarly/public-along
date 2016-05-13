class ActiveDirectoryService
  attr_accessor :ldap

  def initialize
    @ldap ||= begin
      puts "Starting new connection..."
      l = Net::LDAP.new
      l.host = Rails.application.secrets.ad_host
      l.port = 636
      l.encryption(method: :simple_tls)
      l.auth(Rails.application.secrets.ad_svc_user, Rails.application.secrets.ad_svc_user_passwd)
      l.bind
      l
    end
  end

  def create_disabled(employees)
    employees.each do |e|
      if assign_sAMAccountName(e)
        puts "creating #{e.first_name} #{e.last_name}"
        #TODO create a general validation for contingent workers
        if e.contingent_worker_type.present? && e.contract_end_date.blank?
          puts "WARNING: #{e.first_name} #{e.last_name} is a contingent worker and needs a contract_end_date. A disabled Active Directory user has been created, but will not be enabled until the contract_end_date is provided"
        end
        ldap.add(dn: e.dn, attributes: e.attrs)
        puts ldap.get_operation_result
      else
        puts "ERROR: could not find a suitable sAMAccountName for #{e.first_name} #{e.last_name}: Must create AD account manually"
      end
    end
  end

  def activate(employees)
    employees.each do |e|
      #TODO create a general validation for contingent workers
      if e.contingent_worker_type.present? && e.contract_end_date.blank?
        puts "ERROR: #{e.first_name} #{e.last_name} is a contingent worker and needs a contract_end_date. Account not activated."
      else
        ldap.replace_attribute(e.dn, :userAccountControl, "512")
        puts ldap.get_operation_result
      end
    end
  end

  def deactivate(employees)
    employees.each do |e|
        puts "DEACTIVE"
      #TODO create a general validation for contingent workers
      if e.contingent_worker_type.present? && e.contract_end_date.blank?
        puts "ERROR: #{e.first_name} #{e.last_name} is a contingent worker and needs a contract_end_date. Account not activated."
      else
        ldap.replace_attribute(e.dn, :userAccountControl, "514")
        puts ldap.get_operation_result
      end
    end
  end

  def assign_sAMAccountName(employee)
    first = employee.first_name
    last = employee.last_name

    sam_options = [
      (first[0,1] + last).downcase,
      (first + last[0,1]).downcase,
      (first + last).downcase
    ]

    sam_options.each do |sam|
      if find_entry("sAMAccountName", sam).blank?
        employee.sAMAccountName = sam
        break
      end
    end

    puts employee.sAMAccountName
    employee.sAMAccountName.present?
  end

  def find_entry(attr, value)
    ldap.search(
      :base => BASE,
      :filter => Net::LDAP::Filter.eq(attr, value)
    ) do |entry|
      puts "DN #{entry.dn}"
      entry
    end
  end
end
