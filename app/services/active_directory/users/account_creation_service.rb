require 'i18n'

module ActiveDirectoryManager
  # Creates new Active Directory user account from employee data
  module Users
    class SamAccountName
      def initialize(employee)
        @employee = employee
      end

      def assign
        employee.update_attributes(sam_account_name: sam)
      end

      private

      attr_reader :employee
    end

    class AccountCreationService

      attr_reader :connection

      def initialize(connection: nil)
        @connection = connection ||= LdapConnection.new
      end

      def call(dn, attrs)
        assign_sam_account_name(employee)
        attrs = new_acct_attrs(employee)

        connection.ldap.add(dn: dn(employee), attributes: attrs) if employee.sam_account_name.present?
      end

      private

      def attrs(employee)
        Attrs.new(employee)
      end

      def dn(employee)
        Dn.new(employee).dn
      end

      def assign_sam_account_name(employee)
        sam = new_sam_account_name(employee)

        return ErrorHandler.acct_creation_error(employee) if sam.blank?
        ErrorHandler.missing_contract_end_date(employee) if missing_information(employee)
      end

      def new_sam_account_name(employee)
        first_name = transliterated(employee.first_name)
        last_name = transliterated(employee.last_name)

        standard_sam_options(first_name, last_name).each do |sam|
          return sam if connection.find_entry('sAMAccountName', sam).blank?
        end

        numeric_sam_option(first_name, last_name)
      end

      def standard_sam_options(first_name, last_name)
        [(first_name[0, 1] + last_name),
         (first_name + last_name[0, 1]),
         (first_name + last_name)]
      end

      def numeric_sam_option(first_name, last_name)
        int = 1
        while int < 100
          sam = first_name[0, 1] + last_name + int.to_s
          return sam if connection.find_entry('sAMAccountName', sam).blank?
          int += 1
        end
      end

      def transliterated(name)
        I18n.transliterate(name).downcase.gsub(/[^a-z]/i, '')
      end

      def new_acct_attrs(employee)
        attrs(employee).delete_if { |key, value| value.blank? || key == :dn }
      end

      def missing_information(employee)
        !ActivationPolicy.new(employee).record_complete?
      end
    end
  end
end
