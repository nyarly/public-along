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
            if e.save
              Employee.check_manager(e.manager_id)
              workers_to_update << e
              delta.save if delta.present?
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

    def check_new_hire_changes
      check_adp("Pending", 1.year.from_now.change(:usec => 0)) { |e, json|
        if json["workers"].present?
          parser = WorkerJsonParser.new
          workers = parser.sort_workers(json)

          w_hash = workers[0]
          e.assign_attributes(w_hash.except(:status))
        else
          TechTableMailer.alert_email("New hire sync is erroring on #{e.cn}, employee id: #{e.employee_id}.\nPlease contact the developer to help diagnose the problem.").deliver_now
        end
      }
    end

    def check_leave_return
      check_adp("Inactive", 1.day.from_now.change(:usec => 0)) { |e, json, date|
        adp_status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")

        if adp_status == "Active" && e.leave_return_date.blank?
          e.assign_attributes(leave_return_date: date)
        elsif e.leave_return_date.present? && adp_status == "Inactive"
          e.assign_attributes(leave_return_date: nil)
        end
      }
    end

    def check_adp(status, as_of_date, &block)
      update_emps = []

      Employee.where(status: status).find_each do |e|
        json = get_worker_json(e, as_of_date)

        block.call(e, json, as_of_date)

        if e.changed? && e.save
          update_emps << e
        end
      end

      update_ads(update_emps)
    end


    def get_worker_json(e, date)
      begin
      ensure
        m = date.strftime("%m")
        d = date.strftime("%d")
        y = date.strftime("%Y")

        str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/#{e.adp_assoc_oid}?asOfDate=#{m}%2F#{d}%2F#{y}")
        worker_json = JSON.parse(str)
      end
      worker_json
    end

    def update_ads(emp_array)
      if emp_array.present?
        ads = ActiveDirectoryService.new
        ads.update(emp_array)
      end
    end

    def build_emp_delta(employee)
      before = employee.changed_attributes
      after = Hash[employee.changes.map { |k,v| [k, v[1]] }]
      if before.present? && after.present?
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
