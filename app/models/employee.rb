class Employee < ActiveRecord::Base
  validates :first_name,
            presence: true
  validates :last_name,
            presence: true

  def cn
    first_name + " " + last_name
  end

  def dn
    "cn=#{cn},cn=Users,dc=ottest,dc=opentable,dc=com"
  end

  def sAMAccountName
    (first_name[0,1] + last_name).downcase
  end

  def plain_text_password
    "Password!12345"
  end

  def attrs
    {
      cn: cn,
      objectclass: ["top", "person", "organizationalPerson", "user"],
      givenName: first_name,
      sn: last_name,
      sAMAccountName: sAMAccountName,
      mail: sAMAccountName + "@opentable.com",
      unicodePwd: "\"#{plain_text_password}\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
    }
  end

  def ldap
    # TODO use env variables
    l = Net::LDAP.new
    l.host = '192.168.200.6'
    l.port = 636
    l.encryption(method: :simple_tls)
    l.auth('svc_workday@ottest.opentable.com', '4Xdq4yXg')
    l.bind
    l
  end

  def add_to_ad
    ldap.add(dn: dn, attributes: attrs)
    puts ldap.get_operation_result
  end

  def activate_account
    ldap.replace_attribute(dn, :userAccountControl, "512")
    puts ldap.get_operation_result
  end
end
