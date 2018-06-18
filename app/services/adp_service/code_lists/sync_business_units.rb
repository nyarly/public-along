module AdpService
  module CodeLists
    class SyncBusinessUnits < Base
      def self.call
        new.call
      end

      def call
        BusinessUnit.update_all(active: 'f')

        business_units.each { |unit| process_unit_json(unit) }
      end

      private

      def process_unit_json(unit_json)
        code = unit_json['codeValue']
        name = business_unit_name(unit_json)
        current_business_unit = BusinessUnit.find_by(code: code)

        if current_business_unit.present?
          current_business_unit.update(name: name, active: true)
        else
          BusinessUnit.create(code: code, name: name, active: true)
        end
      end

      def business_unit_name(unit_json)
        short_name = unit_json['shortName']
        short_name.presence || unit_json['longName']
      end

      def business_units
        str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/business-units/WFN/1")
        json = JSON.parse(str)
        json['codeLists'].find { |list| list['codeListTitle'] == 'business-units' }['listItems']
      end
    end
  end
end
