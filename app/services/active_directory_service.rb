class ActiveDirectoryService
  attr_accessor :ldap

  def initialize
    @ldap ||= begin
      puts "new connection"
      l = Net::LDAP.new
      l.host = Rails.application.secrets.ad_host
      l.port = 636
      l.encryption(method: :simple_tls)
      l.auth(Rails.application.secrets.ad_svc_user, Rails.application.secrets.ad_svc_user_passwd)
      l.bind
      l
    end
  end
  # create new ad users from list of employees

  def create_disabled(employees)
    employees.each do |e|
      if assign_sAMAccountName(e)
        ldap.add(dn: e.dn, attributes: e.attrs)
        puts ldap.get_operation_result
      else
        puts "could not find a suitable sAMAccountName for #{e.first_name} #{e.last_name}: Must create AD account manually"
      end
    end
  end
  # modify users from list of employees

  def make_normal(employees)
    employees.each do |e|
      ldap.replace_attribute(e.dn, :userAccountControl, "512")
      puts ldap.get_operation_result
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
      if find_entry("sAMAccountName", sam).empty?
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