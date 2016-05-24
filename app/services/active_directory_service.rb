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

  def create_disabled_accounts(employees)
    employees.each do |e|
      if assign_sAMAccountName(e)
        puts "creating #{e.first_name} #{e.last_name}"
        #TODO create a general validation for contract workers
        if e.employee_type != "Regular" && e.contract_end_date.blank?
          puts "WARNING: #{e.first_name} #{e.last_name} is a contract worker and needs a contract_end_date. A disabled Active Directory user has been created, but will not be enabled until the contract_end_date is provided"
        end
        attrs = e.ad_attrs.delete_if { |k,v| v.blank? } # AD#add won't accept nil or empty strings
        ldap.add(dn: e.dn, attributes: attrs)
        e.ad_updated_at = DateTime.now if ldap.get_operation_result.code == 0
      else
        puts "ERROR: could not find a suitable sAMAccountName for #{e.first_name} #{e.last_name}: Must create AD account manually"
      end
    end
  end

  def activate(employees)
    employees.each do |e|
      #TODO create a general validation for contract workers
      if e.employee_type != "Regular" && e.contract_end_date.blank?
        puts "ERROR: #{e.first_name} #{e.last_name} is a contract worker and needs a contract_end_date. Account not activated."
      else
        ldap.replace_attribute(e.dn, :userAccountControl, "512")
      end
    end
  end

  def deactivate(employees)
    employees.each do |e|
      ldap.replace_attribute(e.dn, :userAccountControl, "514")
    end
  end

  def update(employees)
    employees.each do |e|
      ldap_entry = find_entry("employeeID", e.employee_id).first
      if ldap_entry
        attrs = updatable_attrs(e, ldap_entry)
        blank_attrs, populated_attrs = attrs.partition { |k,v| v.blank? }

        delete_attrs(e, ldap_entry, blank_attrs)
        replace_attrs(e, ldap_entry, populated_attrs)
      else
        puts "ERROR: #{e.first_name} #{e.last_name} not found in Active Directory"
      end
    end
  end

  def updatable_attrs(employee, ldap_entry)
    attrs = employee.ad_attrs
    # objectClass, sAMAccountName, mail, and unicodePwd should not be updated via Workday
    [:objectclass, :sAMAccountName, :mail, :unicodePwd].each { |k| attrs.delete(k) }
    # Only update attrs that differ
    attrs.each { |k,v|
      if v == ldap_entry.try(k) || ldap_entry.try(k).include?(v)
        attrs.delete(k)
      end
    }
    attrs
  end

  def delete_attrs(employee, ldap_entry, attrs)
    attrs.each do |k,v|
      ldap.delete_attribute(employee.dn, k, v)
      employee.ad_updated_at = DateTime.now if ldap.get_operation_result.code == 0
    end
  end

  def replace_attrs(employee, ldap_entry, attrs)
    attrs.each do |k,v|
      # Changing cn, co or dept requires a dn renaming
      if [:cn, :co, :department].include?(k)
        ldap.rename(
          :olddn => ldap_entry.dn,
          :newrdn => "cn=#{employee.cn}",
          :delete_attributes => true,
          :new_superior => employee.ou + Rails.application.secrets.ad_ou_base
        )
        employee.ad_updated_at = DateTime.now if ldap.get_operation_result.code == 0
      end

      unless k == :cn
        ldap.replace_attribute(employee.dn, k, v)
        employee.ad_updated_at = DateTime.now if ldap.get_operation_result.code == 0
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

    employee.sAMAccountName.present?
  end

  def find_entry(attr, value)
    ldap.search(
      :base => Rails.application.secrets.ad_ou_base,
      :filter => Net::LDAP::Filter.eq(attr, value)
    ) do |entry|
      puts "DN #{entry.dn}"
      entry
    end
  end
end
