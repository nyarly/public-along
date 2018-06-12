module AdpService
  module CodeLists
    class SyncDepartments < Base
      def self.call
        new.call
      end

      def call
        Department.update_all(status: 'Inactive')

        departments.each { |department_json| process_department_json(department_json) }
      end

      private

      def process_department_json(department_json)
        code = department_json['codeValue']
        name = department_name(department_json)
        department = Department.find_by(code: code)

        if department.present?
          department.update_attributes(name: name, status: 'Active')
        else
          new_department = Department.create(code: code, name: name, status: 'Active')
          PeopleAndCultureMailer.code_list_alert([new_department]).deliver_now
        end
      end

      def department_name(department_json)
        short_name = department_json['shortName']
        short_name.present? ? short_name : department_json['longName']
      end

      def departments
        str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/departments/WFN/1")
        json = JSON.parse(str)
        json['codeLists'].find { |list| list['codeListTitle'] == 'departments' }['listItems']
      end
    end
  end
end
