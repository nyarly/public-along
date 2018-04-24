module ActiveDirectoryManager
  module Groups
    class UpdateService
      def initialize(connection: nil, old_dn, new_dn)
        @connection = connection ||= LdapConnection.new
        @old_dn = old_dn
        @new_dn = new_dn
      end

      def self.run!(old_dn, new_dn)
        self.new(old_dn, new_dn).tap do |service|
          service.update_or_create
        end
      end

      private

      def update_or_create

      end

      attr_accessor :connection
    end
  end
end
