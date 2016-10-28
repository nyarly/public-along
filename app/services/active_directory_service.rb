require "i18n"

class ActiveDirectoryService
  attr_accessor :ldap

  def initialize
    @ldap ||= begin
      l = Net::LDAP.new
      l.host = SECRETS.ad_host
      l.port = 636
      l.encryption(method: :simple_tls)
      l.auth(SECRETS.ad_svc_user, SECRETS.ad_svc_user_passwd)
      l.bind
      l
    end
  end

  def create_disabled_accounts(employees)
    employees.each do |e|
      if assign_sAMAccountName(e)
        if e.contract_end_date_needed?
          TechTableMailer.alert_email("WARNING: #{e.first_name} #{e.last_name} is a contract worker and needs a contract_end_date. A disabled Active Directory user has been created, but will not be enabled until a contract_end_date is provided").deliver_now
        end
        attrs = e.ad_attrs.delete_if { |k,v| v.blank? } # AD#add won't accept nil or empty strings
        attrs.delete(:dn) # need to remove dn for create
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
      elsif !e.onboarding_complete?
        TechTableMailer.alert_email("ERROR: #{e.first_name} #{e.last_name} requires manager to complete onboarding forms. Account not activated.").deliver_now
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
        :new_superior => "ou=Disabled Users,ou=Users," + Rails.application.secrets.ad_ou_base
      )
    end
  end

  def terminate(employees)
    employees.each do |e|
      e.security_profiles.each do |sp|
        sp.access_levels.each do |al|
          remove_from_sec_group(al.ad_security_group, e)
        end
      end
    end
  end

  def update(employees)
    employees.each do |e|
      ldap_entry = find_entry("sAMAccountName", e.sam_account_name).first
      if ldap_entry
        attrs = updatable_attrs(e, ldap_entry)
        blank_attrs, populated_attrs = attrs.partition { |k,v| v.blank? }

        delete_attrs(e, ldap_entry, blank_attrs)
        replace_attrs(e, ldap_entry, populated_attrs)
      else
        TechTableMailer.alert_email("ERROR: #{e.first_name} #{e.last_name} not found in Active Directory. Update failed.").deliver_now
      end
    end
  end

  def updatable_attrs(employee, ldap_entry)
    attrs = employee.ad_attrs
    # objectClass, sAMAccountName, mail, and unicodePwd should not be updated via Workday
    [:objectclass, :sAMAccountName, :mail, :unicodePwd].each { |k| attrs.delete(k) }
    # Only update attrs that differ
    attrs.each { |k,v|
      if (ldap_entry.try(k).present? && ldap_entry.try(k).include?(v)) || (ldap_entry.try(k).blank? && v.blank?)
        attrs.delete(k)
      end
    }
    attrs
  end

  def delete_attrs(employee, ldap_entry, attrs)
    attrs.each do |k,v|
      ldap.delete_attribute(employee.dn, k)
      ldap_success_check(employee, "ERROR: Could not successfully delete #{k}: #{v} for #{employee.cn}.")
    end
  end

  def replace_attrs(employee, ldap_entry, attrs)
    attrs.each do |k,v|
      if k == :dn
        ldap.rename(
          :olddn => ldap_entry.dn,
          :newrdn => "cn=#{employee.cn}",
          :delete_attributes => true,
          :new_superior => employee.ou + SECRETS.ad_ou_base
        )
        ldap_success_check(employee, "ERROR: Could not successfully update #{k}: #{v} for #{employee.cn}.")
      end

      unless k == :cn || k == :dn
        ldap.replace_attribute(employee.dn, k, v)
        ldap_success_check(employee, "ERROR: Could not successfully update #{k}: #{v} for #{employee.cn}.")
      end
    end
  end

  def add_to_sec_group(sec_dn, employee)
    ldap.modify :dn => sec_dn, :operations => [[:add, :member, employee.dn]]
    ldap_success_check(employee, "ERROR: Could not successfully add #{employee.cn} to #{sec_dn}.")
  end

  def remove_from_sec_group(sec_dn, employee)
    ldap.modify :dn => sec_dn, :operations => [[:delete, :member, employee.dn]]
    ldap_success_check(employee, "ERROR: Could not successfully delete #{employee.cn} from #{sec_dn}.")
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
        employee.update_attributes(sam_account_name: sam)
        break
      end
    end

    gen_numeric_sam(employee, first, last) if employee.sam_account_name.blank?

    employee.sam_account_name.present?
  end

  def gen_numeric_sam(employee, first, last)
    n = 1
    while n < 100 do
      sam = first[0,1] + last + n.to_s
      if find_entry("sAMAccountName", sam).blank?
        employee.update_attributes(sam_account_name: sam)
        break
      else
        n += 1
      end
    end
  end

  def find_entry(attr, value)
    ldap.search(
      :base => SECRETS.ad_ou_base,
      :filter => Net::LDAP::Filter.eq(attr, value)
    ) do |entry|
      entry
    end
  end

  def ldap_success_check(employee, error_message)
    if ldap.get_operation_result.code == 0
      employee.update_attributes(:ad_updated_at => DateTime.now)
    elsif ldap.get_operation_result.code == 68 # 68 code is returned if the attr already exists in AD. Just return true in this case
      true
    else
      puts "LDAP ERROR: #{ldap.get_operation_result}"
      puts "EMPLOYEE_ID: #{employee.employee_id}"
      TechTableMailer.alert_email(error_message + ldap.get_operation_result.to_s).deliver_now
    end
  end
end
