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
              Employee.check_manager(e.manager_id)
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

    def check_new_hire_changes
      Employee.where(status: "Pending").find_each do |e|
        # arbitrary future date to see if any info has changed on hire
        # hire date could have been moved forward
        date = e.hire_date + 1.month

        month = date.strftime("%m")
        day = date.strftime("%d")
        year = date.strftime("%Y")

        update_emps = []

        str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/#{e.adp_assoc_oid}?asOfDate=#{month}%2F#{day}%2F#{year}")
        json = JSON.parse(str)

        parser = WorkerJsonParser.new
        workers = parser.sort_workers(json)

        workers.each do |w_hash|
          e = Employee.find_by(employee_id: w_hash[:employee_id])
          e.assign_attributes(w_hash.except(:status))
        end
        if e.changed? && e.save
          update_emps << e
        end

        ads = ActiveDirectoryService.new
        ads.update(update_emps)
      end
    end

    def check_leave_return
      future_date = 1.day.from_now.change(:usec => 0)

      month = future_date.strftime("%m")
      day = future_date.strftime("%d")
      year = future_date.strftime("%Y")

      update_emps = []

      Employee.where(status: "Inactive").find_each do |e|
        str = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/#{e.adp_assoc_oid}?asOfDate=#{month}%2F#{day}%2F#{year}")
        json = JSON.parse(str)

        adp_status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")

        if adp_status == "Active" && e.leave_return_date.blank?
          e.assign_attributes(leave_return_date: future_date)
        elsif e.leave_return_date.present? && adp_status == "Inactive"
          e.assign_attributes(leave_return_date: nil)
        end

        if e.changed? && e.save
          update_emps << e
        end
      end

      ads = ActiveDirectoryService.new
      ads.update(update_emps)
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
