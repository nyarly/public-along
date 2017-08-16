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
      check_adp("Pending", 1.year.from_now.change(:usec => 0)) { |e, json|
        if json["workers"].present?
          parser = WorkerJsonParser.new
          workers = parser.sort_workers(json)
          w_hash = workers[0]

          # If employee will be with OpenTable for less than a year,
          # check for changes within a smaller time window

          if w_hash.blank? && e.contract_end_date.present?
            w = get_worker_json(e, e.contract_end_date - 1.day)
            worker = parser.sort_workers(w)
            w_hash = worker[0]
          end

          if w_hash.present?
            e.assign_attributes(w_hash.except(:status))
          else
            TechTableMailer.alert_email("Cannot get updated ADP info for new contract hire #{e.cn}, employee id: #{e.employee_id}.\nPlease contact the developer to help diagnose the problem.").deliver_now
          end
        else
          Rails.logger.info "New Hire Sync Error"
          Rails.logger.info "#{e.cn}"
          Rails.logger.info "#{json}"
          # TechTableMailer.alert_email("New hire sync is erroring on #{e.cn}, employee id: #{e.employee_id}.\nPlease contact the developer to help diagnose the problem.").deliver_now
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
        delta = build_emp_delta(e)

        if e.changed? && e.save
          Employee.check_manager(e.manager_id)
          delta.save if delta.present?
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

    def send_email?(employee)
      has_changed = employee.changed? && employee.valid?
      has_triggering_change = employee.department_id_changed? || employee.location_id_changed? || employee.worker_type_id_changed? || employee.job_title_id_changed?
      no_previous_changes = employee.emp_deltas.important_changes.blank?

      if has_changed && has_triggering_change
        if no_previous_changes
          true
        else
          last_emailed_on = employee.emp_deltas.important_changes.last.created_at
          if last_emailed_on <= 1.day.ago
            true
          end
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
