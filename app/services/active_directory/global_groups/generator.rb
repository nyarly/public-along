module ActiveDirectory
  module GlobalGroups
    # Creates all Mezzo managed global groups
    class Generator < Base

      def self.call
        new.call
      end

      def self.new_group(code, kind)
        new.new_group(code, kind)
      end

      def call
        geographic
        collection(Department.code_collection, 'Department')
        collection(ParentOrg.code_collection, 'Parent Org')
        manager
      end

      def new_group(code, kind)
        generate_group(code, kind)
        generate_subgroups([code], kind)
      end

      private

      def geographic
        GeographicCollection.all.each { |code| generate_group(code, 'Geographic') }
      end

      def collection(collection, kind)
        collection.each { |coll| generate_group(coll, kind) }
        generate_subgroups(collection, kind)
      end

      def manager
        add("cn=MGR-ALL,ou=Manager,#{global_group_base}", 'group')
      end

      def generate_group(code, kind)
        DIRECTORIES.each do |dir|
          cn = "#{dir[:abbr]}-#{code}"
          add("cn=#{cn},ou=#{kind},ou=#{dir[:name]},#{global_group_base}", 'group')
        end
      end

      def generate_subgroups(collection, name)
        GeographicCollection.all.product(collection).collect do |geo_code, item|
          DIRECTORIES.each do |dir|
            dn = "cn=#{dir[:abbr]}-#{item}-#{geo_code},ou=#{name},ou=#{dir[:name]},#{global_group_base}"
            add(dn, 'group')
          end
        end
      end
    end

    # Collection of active department and parent org names
    class OrgCollection
      def self.all
        Department.code_collection + ParentOrg.code_collection
      end
    end

    # colelction of active country and location names
    class GeographicCollection
      def self.all
        Country.code_collection + Location.code_collection
      end
    end
  end
end
