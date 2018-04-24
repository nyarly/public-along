module ActiveDirectoryManager
  # AD user attributes hash
  module Users
    class Attrs

      delegate :address,
        :department,
        :email,
        :employee_id,
        :first_name,
        :generated_email,
        :job_title,
        :last_name,
        :location,
        :manager,
        :nearest_time_zone,
        :offboard_date,
        :office_phone,
        :sam_account_name,
        :worker_type, to: :employee

      def initialize(employee)
        @employee = employee
        @user_dn = @user_dn ||= DnComposer.new(employee)
        return all
      end

      def all
        {
          cn: user_dn.cn,
          dn: user_dn.dn,
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: first_name,
          sn: last_name,
          displayName: user_dn.cn,
          userPrincipalName: generated_upn,
          sAMAccountName: sam_account_name,
          manager: manager_dn,
          mail: generated_email,
          unicodePwd: encode_password,
          co: location.country,
          accountExpires: generated_account_expires,
          title: job_title_info,
          description: job_title_info,
          employeeType: worker_type.try(:name),
          physicalDeliveryOfficeName: location.name,
          department: department.name,
          employeeID: employee_id,
          telephoneNumber: office_phone,
          streetAddress: address.try(:complete_street),
          l: address.try(:city),
          st: address.try(:state_territory),
          postalCode: address.try(:postal_code)
        }
      end

      private

      def job_title_info
        job_title.name
      end

      def manager_dn
        manager.present? ? DnComposer.new(manager).dn : nil
      end

      def generated_upn
        sam_account_name + '@opentable.com' if sam_account_name
      end

      def generated_account_expires
        # The expiration date needs to be set a day after term date
        # AD expires the account at midnight of the day before the expiry date

        if offboard_date.present?
          expiration_date = offboard_date + 1.day
          time_conversion = ActiveSupport::TimeZone.new(nearest_time_zone).local_to_utc(expiration_date)
          DateTimeHelper::FileTime.wtime(time_conversion)
        else
          NEVER_EXPIRES
        end
      end

      def encode_password
        "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
      end

      attr_reader :employee, :user_dn
    end
  end
end
