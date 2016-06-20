require "i18n"

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
        if e.contract_end_date_needed?
          TechTableMailer.alert_email("WARNING: #{e.first_name} #{e.last_name} is a contract worker and needs a contract_end_date. A disabled Active Directory user has been created, but will not be enabled until a contract_end_date is provided").deliver_now
        end
        attrs = e.ad_attrs.delete_if { |k,v| v.blank? } # AD#add won't accept nil or empty strings
        ldap.add(dn: e.dn, attributes: attrs)
        ldap_success_check(e, "ERROR: Creation of disabled account for #{e.first_name} #{e.last_name} failed.")
      else
        TechTableMailer.alert_email("ERROR: could not find a suitable sAMAccountName for #{e.first_name} #{e.last_name}: Must create AD account manually").deliver_now
      end
    end
  end

  def activate(employees)
    employees.each do |e|
      if e.contract_end_date_needed?
        TechTableMailer.alert_email("ERROR: #{e.first_name} #{e.last_name} is a contract worker and needs a contract_end_date. Account not activated.").deliver_now
      else
        ldap.replace_attribute(e.dn, :userAccountControl, "512")
      end
    end
  end

  def deactivate(employees)
    employees.each do |e|
      ldap.replace_attribute(e.dn, :userAccountControl, "514")
      ldap.rename(
        :olddn => e.dn,
        :newrdn => "cn=#{e.cn}",
        :delete_attributes => true,
        :new_superior => "ou=Disabled Users," + Rails.application.secrets.ad_ou_base
      )
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
        TechTableMailer.alert_email("ERROR: #{e.first_name} #{e.last_name} not found in Active Directory").deliver_now
      end
    end
  end

  def updatable_attrs(employee, ldap_entry)
    attrs = employee.ad_attrs
    # objectClass, sAMAccountName, mail, and unicodePwd should not be updated via Workday
    [:objectclass, :sAMAccountName, :mail, :unicodePwd].each { |k| attrs.delete(k) }
    # Only update attrs that differ
    attrs.each { |k,v|
      if (ldap_entry.try(k).present? && ldap_entry.try(k).include?(v)) || (ldap_entry.try(k).blank? && v == nil)
        attrs.delete(k)
      end
    }
    attrs
  end

  def delete_attrs(employee, ldap_entry, attrs)
    attrs.each do |k,v|
      ldap.delete_attribute(employee.dn, k, v)
      ldap_success_check(employee, "ERROR: Could not successfully update #{k}: #{v} for #{employee.first_name} #{employee.last_name}.")
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
        ldap_success_check(employee, "ERROR: Could not successfully update #{k}: #{v} for #{employee.first_name} #{employee.last_name}.")
      end

      unless k == :cn
        ldap.replace_attribute(employee.dn, k, v)
        ldap_success_check(employee, "ERROR: Could not successfully update #{k}: #{v} for #{employee.first_name} #{employee.last_name}.")
      end
    end
  end

  def assign_sAMAccountName(employee)
    first = I18n.transliterate(employee.first_name).downcase.gsub(/[^a-z]/i, '')
    last = I18n.transliterate(employee.last_name).downcase.gsub(/[^a-z]/i, '')

    sam_options = [
      (first[0,1] + last),
      (first + last[0,1]),
      (first + last)
    ]

    sam_options.each do |sam|
      if find_entry("sAMAccountName", sam).blank?
        employee.sAMAccountName = sam
        break
      end
    end

    gen_numeric_sam(employee, first, last) if employee.sAMAccountName.blank?

    employee.sAMAccountName.present?
  end

  def gen_numeric_sam(employee, first, last)
    n = 1
    while n < 100 do
      sam = first[0,1] + last + n.to_s
      if find_entry("sAMAccountName", sam).blank?
        employee.sAMAccountName = sam
        break
      else
        n += 1
      end
    end
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

  def ldap_success_check(employee, error_message)
    if ldap.get_operation_result.code == 0
      employee.ad_updated_at = DateTime.now
    else
      TechTableMailer.alert_email(error_message).deliver_now
    end
  end
end
