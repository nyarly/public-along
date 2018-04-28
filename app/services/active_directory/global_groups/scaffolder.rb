module ActiveDirectory
  module GlobalGroups
    # Creates the global group OU structure
    class Scaffolder < Base

      def self.call
        new.call
      end

      def call
        basic
        worker_types
        group_types
      end

      private

      def basic
        base = SECRETS.ad_mezzo_base.to_s
        add(base, 'organizationalUnit')
        add("ou=Groups,#{base}", 'organizationalUnit')
        add("ou=Global Groups,ou=Groups,#{base}", 'organizationalUnit')
      end

      def worker_types
        dns = DIRECTORIES.map { |dir| "ou=#{dir[:name]},#{global_group_base}" }
        dns.map { |dn| add(dn, 'organizationalUnit') }
      end

      def group_types
        GROUP_TYPES.product(DIRECTORIES).collect do |group_type, dir|
          dn = "ou=#{group_type},ou=#{dir[:name]},#{global_group_base}"
          add(dn, 'organizationalUnit')
        end
      end
    end
  end
end
