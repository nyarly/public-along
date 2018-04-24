module ActiveDirectoryManager
  module Users
    class Dn
      attr_reader :employee

      delegate :first_name, :last_name, :status, :department, :location, to: :employee

      def initialize(employee)
        @employee = employee
      end

      def cn
        first_name + ' ' + last_name
      end

      def dn
        "cn=#{cn}," + ou + SECRETS.ad_ou_base
      end

      private

      def ou
        return 'ou=Disabled Users,' if status == 'terminated'

        match = OUS.select { |_, value|
          value[:department].include?(department.name) && value[:country].include?(location.country)
        }
        return match.keys[0] if match.length == 1

        use_provisional
      end

      def use_provisional
        # put worker in provisional OU if it cannot find one
        send_techtable_warning
        'ou=Provisional,ou=Users,'
      end

      def send_techtable_warning
        TechTableMailer.alert_email(warning_msg).deliver_now
      end

      def warning_msg
        "WARNING: could not find an exact ou match for #{first_name} #{last_name}; placed in default ou. To remedy, assign appropriate department and country values in Mezzo or contact your developer to create an OU mapping for this department and location combination."
      end
    end
  end
end
