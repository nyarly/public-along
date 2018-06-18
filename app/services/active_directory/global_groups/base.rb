module ActiveDirectory
  module GlobalGroups
    # Shared and utility methods
    class Base

      GROUP_TYPES = ['Geographic', 'Parent Org', 'Department'].freeze
      DIRECTORIES = [
        { name: 'Temporary', abbr: 'TEMP' },
        { name: 'Contractor', abbr: 'CONT' },
        { name: 'Employee', abbr: 'EMP' },
        { name: 'Manager', abbr: 'MGR' }
      ].freeze

      def initialize(connection: nil)
        @connection = connection ||= LdapConnection.new
      end

      def add(dist_name, object_class)
        cn = CnFromDn.convert(dist_name, object_class)
        connection.ldap.add(dn: dist_name, attributes: { cn: cn, objectClass: ['top', object_class] })
      end

      def global_group_base
        "ou=Global Groups,ou=Groups,#{SECRETS.ad_mezzo_base}"
      end

      def manager_base
        "ou=Manager,#{global_group_base}"
      end

      attr_reader :connection
    end

    # Takes a DN and extracts the CN
    class CnFromDn
      def self.convert(dist_name, object_class)
        regex = object_class == 'group' ? /cn=(.*?),/ : /ou=(.*?),/
        dist_name.gsub(regex).first.partition('=').last.delete(',')
      end
    end
  end
end
