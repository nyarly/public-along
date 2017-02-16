module AdpService
  class Workers < Base

    def create_sidekiq_workers
      create_worker_urls.each do |url|
        AdpWorker.perform_async(url)
      end
    end

    def create_worker_urls
      count = worker_count
      pos = 0
      urls = []
      while pos <= count
        urls << "https://#{SECRETS.adp_api_domain}/hr/v2/workers?$top=25&$skip=#{pos}"
        pos += 25
      end
      urls
    end

    def worker_count
      begin
      ensure
        str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers?$select=workers/workerStatus&$top=1&count=true")
        json = JSON.parse(str)
        count = json["meta"]["totalNumber"]
      end
      count
    end

    def sync_workers(url)
      begin
      ensure
        str = get_json_str(url)
      end

      unless str == nil
        json = JSON.parse(str)
        parser = AdpService::WorkerJsonParser.new

        workers_to_update = []
        workers = parser.sort_workers(json)

        workers.each do |w|
          e = Employee.find_by(employee_id: w[:employee_id])
          if e.present?
            e.update_attributes(w)
            workers_to_update << e
          else
            first_name = w["person"]["legalName"]["nickName"].present? ? w["person"]["legalName"]["nickName"] : w["person"]["legalName"]["givenName"]
            last_name = w["person"]["legalName"]["familyName1"]
            employee_id = w["workerID"]["idValue"]
            puts first_name + ", " + last_name + ":" + employee_id
          end
        end

        ads = ActiveDirectoryService.new
        ads.update(workers_to_update)
      end
    end
  end
end
