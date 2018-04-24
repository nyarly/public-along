module ActiveDirectoryManager
  class Group

    GLOBAL_GROUP_CATEGORIES = ['Temp', 'Contractor', 'Employee']

    def initialize(connection: nil)
      @connection = connection ||= LdapConnection.new
    end

    def location_groups
      Location.all.find_each do |location|
        cn = location.name
        GLOBAL_GROUP_CATEGORIES.each do |category|
          dn = "cn=#{cn},ou=Geographic,#{category},ou=Global Groups,ou=Groups," + base
          new_ou(cn, dn)
        end
      end
    end

    def country_groups
      Country.all.find_each do |country|
      end
    end

    # def new_security_group(name, base)
    #   ldap.add(dn: "cn=PaulaTest,OU=OT Applications,OU=Security Groups,OU=OT,DC=ottest,DC=opentable,DC=com", attributes: { objectclass: ["top", "group"] })
    # end

    def new_ou(cn, dn)
      connection.ldap.add(dn: dn, attributes: { cn: cn, objectClass: ["top", "organizationalUnit"] })
    end

    def base
      SECRETS.ad_mezzo_base
    end

    def new_ou(name, base)
      # ad.ldap.add(dn: "ou=Employees,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: 'Employees', objectClass: ["top", "organizationalUnit"] })
      dn = "OU=#{name},#{base}"
      ldap.add(dn: dn, attributes: { cn: name, objectclass: ['top', 'organizationalUnit']})
    end

    def update_object(old_name, new_name)
      # ldap.rename(olddn: "OU=Global Groups,OU=Groups,OU=OT,DC=ottest,DC=opentable,DC=com", newrdn: "OU=Fancy Groups", delete_attributes: true, new_superior: "OU=Groups,OU=OT,DC=ottest,DC=opentable,DC=com")
    end
  end
end



# ad.ldap.add(dn: "ou=Geographic,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: 'Geographic', objectClass: ["top", "organizationalUnit"] })
# ad.ldap.add(dn: "ou=Department,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: 'Department', objectClass: ["top", "organizationalUnit"] })
# ad.ldap.add(dn: "ou=Parent Department,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: "Parent Department", objectClass: ["top", "organizationalUnit"] })




#   ad.ldap.add(dn: "ou=#{c.name},OU=Department,OU=Contractor,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{c.name}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{c.name},OU=Department,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{c.name}', objectClass: ["top", "organizationalUnit"] })

# Department.where(status: 'Active').each do |c|
#   ad.ldap.add(dn: "ou=#{c.name},OU=Department,OU=Employee,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{c.name}', objectClass: ["top", "organizationalUnit"] })
# end


# Location.where(status: 'Active').each do |t|
#   ad.ldap.add(dn: "ou=#{t.name},OU=Geographic,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.name}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{t.name},OU=Geographic,OU=Contractor,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.name}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{t.name},OU=Geographic,OU=Employee,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.name}', objectClass: ["top", "organizationalUnit"] })
# end

# ParentOrg.all.each do |t|
#   ad.ldap.add(dn: "ou=#{t.name},OU=Parent Department,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.name}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{t.name},OU=Parent Department,OU=Employee,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.name}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{t.name},OU=Parent Department,OU=Contractor,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.name}', objectClass: ["top", "organizationalUnit"] })
# end

# Department.all.each do |t|
#   ad.ldap.add(dn: "ou=#{t.code},OU=Department,OU=Temp,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.code}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{t.code},OU=Department,OU=Employee,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.code}', objectClass: ["top", "organizationalUnit"] })
#   ad.ldap.add(dn: "ou=#{t.code},OU=Department,OU=Contractor,OU=Global Groups,OU=Groups,OU=Mezzo Managed,DC=ottest,DC=opentable,DC=com", attributes: { cn: '#{t.code}', objectClass: ["top", "organizationalUnit"] })
# end
