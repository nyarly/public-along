module AdpService
  module CodeLists
    class SyncWorkerTypes < Base

      def self.call
        new.call
      end

      def call
        WorkerType.update_all(status: 'Inactive')

        worker_types.each { |worker_type_json| process_worker_type_json(worker_type_json) }
      end

      private

      def process_worker_type_json(json)
        code = json['codeValue']
        name = worker_type_name(json)
        worker_type = WorkerType.find_by(code: code)

        if worker_type.present?
          worker_type.update(name: name, status: 'Active')
        elsif code.present?
          new_worker_type = WorkerType.create(code: code, name: name, status: 'Active')
          PeopleAndCultureMailer.code_list_alert([new_worker_type]).deliver_now
        end
      end

      def worker_type_name(json)
        short_name = json['shortName']
        short_name.presence || json['longName']
      end

      def worker_types
        str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/meta")
        json = JSON.parse(str)
        json['meta']['/workers/workAssignments/workerTypeCode']['codeList']['listItems']
      end
    end
  end
end
