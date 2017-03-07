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
        adp_only = []
        workers = parser.sort_workers(json)

        workers.each do |w|
          e = Employee.find_by(employee_id: w[:employee_id])
          if e.present?
            e.assign_attributes(w)
            delta = build_emp_delta(e)
            send_email = send_email?(e)
            if e.save
              workers_to_update << e
              delta.save if delta.present?
              EmployeeWorker.perform_async("Security Access", e.id) if send_email == true
            end
          else
            adp_only << "{ first_name: #{w[:first_name]}, last_name: #{w[:last_name]}, employee_id: #{w[:employee_id]})"
          end
        end unless workers.blank?

        unless workers_to_update.blank?
          ads = ActiveDirectoryService.new
          ads.update(workers_to_update)
        end

        {updated: workers_to_update, not_found: adp_only}
      end
    end

    def send_email?(employee)
      if employee.changed? && employee.valid?
        if employee.manager_id_changed? || employee.department_id_changed? || employee.location_id_changed?
          true
        end
      end
    end

    def build_emp_delta(employee)
      before = employee.changed_attributes
      after = Hash[employee.changes.map { |k,v| [k, v[1]] }]
      unless before.empty? && after.empty?
        emp_delta = EmpDelta.new(
          employee_id: employee.id,
          before: before,
          after: after
        )
      end
      emp_delta
    end
  end
end
