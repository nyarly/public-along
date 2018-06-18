module AdpService
  module CodeLists
    class SyncJobTitles < Base
      def self.call
        new.call
      end

      def call
        JobTitle.update_all(status: 'Inactive')

        job_titles.each { |title_json| process_title_json(title_json) }
      end

      private

      def process_title_json(title_json)
        code = title_json['codeValue']
        name = job_title_name(title_json)

        job_title = JobTitle.find_or_create_by(code: code)
        job_title.update(name: name, status: 'Active')
      end

      def job_title_name(title_json)
        short_name = title_json['shortName']
        short_name.presence || title_json['longName']
      end

      def job_titles
        str = get_json_str("https://#{SECRETS.adp_api_domain}/codelists/hr/v3/worker-management/job-titles/WFN/1")
        json = JSON.parse(str)
        json['codeLists'].find { |list| list['codeListTitle'] == 'job-titles' }['listItems']
      end
    end
  end
end
