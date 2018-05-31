module AdpService
  module CodeLists
    class SyncLocations < Base
      def self.call
        new.call
      end

      def call
        Location.update_all(status: 'Inactive')

        locations.each { |location_json| process_location_json(location_json) }
      end

      private

      def process_location_json(json)
        code = json['codeValue']
        name = location_name(json)
        location = Location.find_by(code: code)

        if location.present?
          location.update_attributes(name: name, status: 'Active')
        else
          new_location(code, name)
        end
      end

      def new_location(code, name)
        new_location = Location.create(code: code, name: name, status: 'Active')
        default_country = Country.find_or_create_by(iso_alpha_2_code: 'Pending Assignment', name: 'Pending Assignment')
        new_location.build_address(country_id: default_country.id)
        new_location.save!

        PeopleAndCultureMailer.code_list_alert([new_location]).deliver_now
      end

      def location_name(json)
        short_name = json['shortName'].present?
        short_name.present? ? short_name : json['longName']
      end

      def locations
        str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/locations/WFN/1")
        json = JSON.parse(str)
        json['codeLists'].find { |list| list['codeListTitle'] == 'locations' }['listItems']
      end
    end
  end
end
