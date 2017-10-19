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
        parser = WorkerJsonParser.new
        workers_to_update = []
        adp_only = []
        workers = parser.sort_workers(json)

        workers.each do |w|
          e = Employee.find_by_employee_id(w[:adp_employee_id])
          if e.present?
            profiler = EmployeeProfile.new
            profiler.update_employee(e, w)
            ManagerAccessService.new(e.manager).process! if e.manager.present?

            workers_to_update << e
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

    def check_future_changes
      Employee.where("status LIKE ? OR status LIKE ?", "pending", "inactive").find_each do |e|
        EmployeeChangeWorker.perform_async(e.id)
      end
    end

    def look_ahead(e)
      if e.status == "pending"
        check_new_hire_change(e)
      else
        # inactive worker status
        check_leave_return(e)
      end
    end

    def check_new_hire_change(e)
      if e.contract_end_date.present?
        future_date = e.contract_end_date - 1.day
      else
        future_date = 1.year.from_now.change(:usec => 0)
      end

      json = get_worker_json(e, future_date)
      adp_status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")

      if adp_status.present? and adp_status == "Active"
        parser = WorkerJsonParser.new
        workers = parser.sort_workers(json)
        w_hash = workers[0]
        profiler = EmployeeProfile.new
        profiler.update_employee(e, w_hash.except(:status, :profile_status))
        ManagerAccessService.new(e.manager).process! if e.manager.present?

        if e.updated_at >= 1.minute.ago
          ad = ActiveDirectoryService.new
          ad.update([e])
        end
      else
        return false
        # TechTableMailer.alert_email("Cannot get updated ADP info for new contract hire #{e.cn}, employee id: #{e.employee_id}.\nPlease contact the developer to help diagnose the problem.").deliver_now
      end
    end

    def check_leave_return(e)
      future_date = 1.day.from_now.change(:usec => 0)
      json = get_worker_json(e, future_date)
      adp_status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")

      if adp_status == "Active" && e.leave_return_date.blank?
        e.assign_attributes(leave_return_date: future_date)
      elsif e.leave_return_date.present? && adp_status == "Inactive"
        e.assign_attributes(leave_return_date: nil)
      end

      delta = EmpDelta.build_from_profile(e.current_profile)

      if e.changed? and e.save!
        ad = ActiveDirectoryService.new
        ad.update([e])
      end

      delta.save! if delta.present?
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
  end
end
