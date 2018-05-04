require "i18n"

class ActiveDirectoryService
  attr_accessor :ldap, :errors

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
    @errors = {}
  end

  def create_disabled_accounts(employees)
    employees.each do |e|
      assign_sAMAccountName(e)

      return account_creation_error(e) if e.sam_account_name.blank?

      needs_contract_end_date(e) if !ActivationPolicy.new(e).record_complete?

      attrs = e.ad_attrs.delete_if { |k,v| v.blank? } # AD#add won't accept nil or empty strings
      attrs.delete(:dn) # need to remove dn for create
      ldap.add(dn: e.dn, attributes: attrs)

      return account_creation_error(e) if ldap.get_operation_result.code != 0

      e.update_attributes(:ad_updated_at => DateTime.now)
    end
  end

  def activate(employees)
    employees.each do |e|
      return needs_contract_end_date(e) if !ActivationPolicy.new(e).record_complete?
      return needs_onboard_form(e) if !ActivationPolicy.new(e).onboarded?

      ldap.replace_attribute(e.dn, :userAccountControl, "512")
    end
  end

  def deactivate(employees)
    employees.each do |e|
      ldap_entry = find_entry("sAMAccountName", e.sam_account_name).first
      if ldap_entry.present?
        ldap.replace_attribute(ldap_entry.dn, :userAccountControl, "514")
        ldap.rename(
          :olddn => ldap_entry.dn,
          :newrdn => "cn=#{e.cn}",
          :delete_attributes => true,
          :new_superior => "ou=Disabled Users," + Rails.application.secrets.ad_ou_base
        )
      end
    end
  end

  def terminate(employees)
    employees.each do |employee|
      ldap_entry = find_entry('sAMAccountName', employee.sam_account_name).first

      remove_memberships_failure(employee, worker_not_found_msg(employee)) if ldap_entry.blank?

      if ldap_entry.present?
        if ldap_entry.respond_to? :memberOf
          results = []
          memberships = ldap_entry.memberof

          memberships.each do |membership|
            results << modify_sec_group('delete', membership, employee)
          end
          failures = scan_for_failed_ldap_transactions(results.flatten)
          remove_memberships_failure(employee, failures) if failures.present?
        end
      end
    end
  end

  def update(employees)
    employees.each do |e|
      ldap_entry = find_entry("sAMAccountName", e.sam_account_name).first
      results = []
      failures = []

      return update_failure(e, worker_not_found_msg(e)) if ldap_entry.blank?

      attrs = updatable_attrs(e, ldap_entry)
      blank_attrs, populated_attrs = attrs.partition { |k,v| v.blank? }

      results << delete_attrs(e, ldap_entry, blank_attrs) if blank_attrs.present?
      results << replace_attrs(e, ldap_entry, populated_attrs) if populated_attrs.present?

      failed_ldap_transactions = scan_for_failed_ldap_transactions(results.flatten)
      failures << failed_ldap_transactions if failed_ldap_transactions.present?

      return update_failure(e, failures) if failures.present?
      results
    end
  end

  def updatable_attrs(employee, ldap_entry)
    attrs = employee.ad_attrs
    # objectClass, sAMAccountName, mail, userPrincipalName, and unicodePwd should not be updated via Mezzo
    [:objectclass, :sAMAccountName, :mail, :userPrincipalName, :unicodePwd].each { |k| attrs.delete(k) }
    # Only update attrs that differ
    attrs.each { |k,v|
      # LDAP returns ASCII-8BIT, coerce Mezzo data to this format for compare
      val = v.present? ? v.force_encoding(Encoding::ASCII_8BIT) : v
      if (ldap_entry.try(k).present? && ldap_entry.try(k).include?(val)) || (ldap_entry.try(k).blank? && val.blank?)
        attrs.delete(k)
      end
    }
    attrs
  end

  def delete_attrs(employee, ldap_entry, attrs)
    results = []
    attrs.each do |k,v|
      ldap.delete_attribute(ldap_entry.dn, k)
      results << { dn: ldap_entry.dn, attribute: k.to_s, action: "delete" }.merge(ldap_success_check(employee))
    end
    results
  end

  def replace_attrs(employee, ldap_entry, attrs)
    results = []
    attrs.each do |k,v|
      if k == :dn
        ldap.rename(
          :olddn => ldap_entry.dn,
          :newrdn => "cn=#{employee.cn}",
          :delete_attributes => true,
          :new_superior => employee.ou + SECRETS.ad_ou_base
        )
        results << { dn: ldap_entry.dn, attribute: k.to_s, action: "replace" }.merge(ldap_success_check(employee))
      end

      unless k == :cn || k == :dn
        ldap.replace_attribute(employee.dn, k, v)
        results << { dn: ldap_entry.dn, attribute: k.to_s, action: "replace" }.merge(ldap_success_check(employee))
      end
    end
    results
  end

  # add or remove security group for employee
  # action parameter can be "add" or "delete" as string
  def modify_sec_group(action, sec_dn, employee)
    ldap.modify :dn => sec_dn, :operations => [[action.to_sym, :member, employee.dn]]
    { dn: employee.dn, sec_dn: sec_dn, action: action }.merge(ldap_success_check(employee))
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

  def ldap_success_check(employee)
    results = ldap.get_operation_result
    result_code = results.code
    status = "failure"

    # 0 code is returned on success
    employee.update_attributes(:ad_updated_at => DateTime.now) if result_code == 0
    # 68 code is returned if the attr already exists in AD, and we count this as success
    status = "success" if result_code == 0 || result_code == 68
    { status: status, code: result_code, message: results.message }
  end

  def scan_for_failed_ldap_transactions(results)
    failures = []
    results.each do |r|
      if r[:status] == "failure"
        failures << r
      end
    end
    return failures if failures.present?
  end

  def worker_not_found_msg(e)
    { message: "#{e.cn} not found in Active Directory" }
  end

  def account_creation_error(e)
    e.update_attributes(email: nil, sam_account_name: nil)

    subject = "Active Directory Account Creation Failure"
    message = "An Active Directory account could not be created for #{e.cn}."
    result = ldap.get_operation_result
    data = { status: "failure", code: result.code, message: result.message }

    Errors::Handler.new(TechTableMailer, subject, message, [data]).process!

    @errors[:active_directory] = "Creation of disabled account for #{e.first_name} #{e.last_name} failed. Check the record for errors and re-submit."
  end

  def needs_contract_end_date(e)
    # should be an email to pc ops
    subject = "Missing Worker End Date for #{e.cn}"
    message = "#{e.cn} is a contingent worker and needs a worker end date in ADP. A disabled Active Directory user has been created, but will not be enabled until a contract end date is provided."
    Errors::Handler.new(PeopleAndCultureMailer, subject, message, []).process!
    Errors::Handler.new(TechTableMailer, subject, message, []).process!
  end

  def needs_onboard_form(e)
    subject = "Onboarding Failure for #{e.cn}"
    message = "#{e.cn} requires a manager onboarding form. Account was not activated."
    Errors::Handler.new(PeopleAndCultureMailer, subject, message, []).process!
    Errors::Handler.new(TechTableMailer, subject, message, []).process!
  end

  def update_failure(e, failures)
    subject = "#{e.cn} Couldn't be Updated in Active Directory"
    message = "Update failed."
    Errors::Handler.new(TechTableMailer, subject, message, failures).process!
  end

  def sec_access_update_failure(e, failures)
    subject = "Failed Security Access Change for #{e.cn}"
    message = "Mezzo received a request to add and/or remove #{e.cn} from security groups in Active Directory. One or more of these transactions have failed."
    Errors::Handler.new(TechTableMailer, subject, message, failures).process!
  end

  def remove_memberships_failure(e, failures)
    subject = "Failed to remove #{e.cn} from AD groups"
    message = "Mezzo attempted to remove #{e.cn} from one or more Active Directory memberships. One or more of these transactions have failed."
    Errors::Handler.new(TechTableMailer, subject, message, failures).process!
  end
end
