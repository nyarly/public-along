class Employee < ActiveRecord::Base
  validates :first_name,
            presence: true
  validates :last_name,
            presence: true

  attr_accessor :sAMAccountName

  def cn
    first_name + " " + last_name
  end

  def dn
    "cn=#{cn},cn=Users,dc=ottest,dc=opentable,dc=com" #TODO needs correct ou structure
  end

  def plain_text_password
    "Password!12345" #TODO What temp password are we supposed to use
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
    # {
    #   cn: cn,
    #   objectclass: ["top", "person", "organizationalPerson", "user"],
    #   givenName: first_name,
    #   sn: last_name,
    #   unicodePwd: "\"#{plain_text_password}\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
    # }
  end
end
