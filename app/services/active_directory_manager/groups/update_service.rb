module ActiveDirectoryManager
  module Groups
    class UpdateService
      def initialize(connection: nil)
        @connection = connection ||= LdapConnection.new
        @old_dn = old_dn
        @new_dn = new_dn
      end

      def self.run!()
        self.new(old_dn, new_dn).tap do |service|
          service.update_or_create
        end
      end

      private

      def update_or_create
        puts 'hi'
      end

      attr_accessor :connection
    end
  end
end
