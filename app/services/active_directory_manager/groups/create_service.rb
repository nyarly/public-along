module ActiveDirectoryManager
  module Groups

    # Creates all the necessary OUs for mezzo managed groups
    class CreateService
      GLOBAL_GROUP_CATEGORIES = ['Temp', 'Contractor', 'Employee']
      GROUP_TYPES = ['Geographic', 'Parent Org', 'Department']

      def initialize(connection: nil)
        @connection = connection ||= LdapConnection.new
      end

      def generate_worker_type_groups
        GLOBAL_GROUP_CATEGORIES.each do |category|
          dn = "ou=#{category},#{global_group_base}"
          add(dn)
        end
      end

      def generate_group_type_groups
        GLOBAL_GROUP_CATEGORIES.each do |category|
          GROUP_TYPES.each do |group_type|
            dn = "ou=#{group_type},ou=#{category},#{global_group_base}"
            add(dn)
          end
        end
      end

      def generate_manager_group
        add(manager_base)
      end

      def generate_all_manager_groups
        generate_manager_group

        group = GeographicNameCollection.all + OrgNameCollection.all
        group.map { |name| add("ou=#{name},#{manager_base}") }
        generate_all_manager_subgroups
      end

      def pairs
        OrgNameCollection.all.map { |name| GeographicNameCollection.all.map  }
      end

      def generate_all_manager_subgroups
        OrgNameCollection.all.each do |org|
          GeographicNameCollection.all.each do |name|
            add("ou=#{name},ou=#{org},#{manager_base}")
          end
        end
      end

      def generate_all_geographic_groups
        GeographicNameCollection.all.each { |name| new_category_ou(name, 'Geographic') }
      end

      def generate_all_department_groups
        Department.name_collection.each { |dept| new_category_ou(dept, 'Department') }
        generate_all_department_locations
      end

      def generate_all_department_locations
        Department.name_collection.each do |department|
          GeographicNameCollection.all.each do |name|
            GLOBAL_GROUP_CATEGORIES.each do |category|
              add("ou=#{name},ou=#{department},ou=Department,ou=#{category},#{global_group_base}")
            end
          end
        end
      end

      def generate_all_parent_org_groups
        ParentOrg.name_collection.each { |org| new_category_ou(org, 'Parent Org') }
        generate_all_parent_org_locations
      end

      def generate_all_parent_org_locations
        ParentOrg.name_collection.each do |parent_org|
          GeographicNameCollection.all.each do |name|
            GLOBAL_GROUP_CATEGORIES.each do |category|
              add("ou=#{name},ou=#{parent_org},ou=Parent Org,ou=#{category},#{global_group_base}")
            end
          end
        end
      end

      private

      attr_reader :connection

      def add(dn)
        cn = CnFromDn.convert(dn)
        connection.ldap.add(dn: dn, attributes: { cn: cn, objectClass: ['top', 'organizationalUnit'] })
      end

      def new_category_ou(name, kind)
        GLOBAL_GROUP_CATEGORIES.each do |category|
          add("ou=#{name},ou=#{kind},ou=#{category},#{global_group_base}")
        end
      end

      def global_group_base
        "ou=Global Groups,ou=Groups,ou=Mezzo Managed,dc=ottest,dc=opentable,dc=com"
      end

      def manager_base
        "ou=Managers,#{global_group_base}"
      end
    end

    # Collection of active department and parent org names
    class OrgNameCollection
      def self.all
        Department.name_collection + ParentOrg.name_collection
      end
    end

    # colelction of active country and location names
    class GeographicNameCollection
      def self.all
        Country.name_collection + Location.name_collection
      end
    end

    # Takes a DN and extracts the CN
    class CnFromDn
      def self.convert(dn)
        dn.gsub(/ou=(.*?),/).first.partition('=').last.gsub(/,/, "")
      end
    end
  end
end
