module AdpService
  class Events < Base

    def get_events
      str = get_json_str("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages")
      body = str.body

      if body.present?
        get_events if process_event(str, body)
      else
        return false
      end
    end

    def process_event(str, body)
      event_body = JSON.dump(redact_confidential_info(body))

      ae = AdpEvent.new(
        json: event_body,
        msg_id: str.to_hash["adp-msg-msgid"][0],
        kind: kind(event_body),
        status: "New"
      )

      if ae.save
        sort_event(ae)
        return true
      else
        return false
      end
    end

    def sort_event(adp_event)
      case adp_event.kind
      when "worker.hire"
        if process_hire(adp_event)
          adp_event.update_attributes(status: "Processed")
        end
      when "worker.terminate"
        if process_term(adp_event)
          adp_event.update_attributes(status: "Processed")
        end
      when "worker.on-leave"
        if process_leave(adp_event)
          adp_event.update_attributes(status: "Processed")
        end
      when "worker.rehire"
        if process_rehire(adp_event)
          adp_event.update_attributes(status: "Processed")
        end
      end
      del_event(adp_event.msg_id)
    end

    def process_hire(event)
      json = JSON.parse(event.json)

      if is_rehire?(json)
        worker_hash = event_json_to_hash(json)
        send_onboard_with_event(event) unless worker_hash[:manager_id].blank?
        return false
      else
        profiler = EmployeeProfile.new
        employee = profiler.new_employee(event)
        employee.hire!
      end
    end

    def process_term(event)
      json = JSON.parse(event.json)
      employee = Employee.find_by_employee_id(worker_id(json))
      term_date = term_date(json)

      if employee.present? && !job_change?(employee, term_date)
        employee.assign_attributes(termination_date: term_date)
        employee.current_profile.assign_attributes(end_date: term_date)

        if is_retroactive?(employee, term_date)
          process_retro_term(employee)
        else
          EmpDelta.build_from_profile(employee.current_profile).save!

          if employee.save!
            employee.start_offboard_process!
          else
            return false
          end
        end
      end
    end

    def process_retro_term(employee)
      employee.current_profile.terminate
      employee.terminate_immediately
      EmpDelta.build_from_profile(employee.current_profile).save!
      employee.save! && employee.current_profile.save!
    end

    def process_leave(event)
      json = JSON.parse(event.json)
      employee = Employee.find_by_employee_id(worker_id(json))

      unless employee.blank?
        leave_date = leave_date(json)
        employee.assign_attributes(leave_start_date: leave_date)
        if is_retroactive?(employee, leave_date)
          employee.current_profile.start_leave
          employee.leave_immediately
          EmpDelta.build_from_profile(employee.current_profile).save!
          employee.save!
        else
          EmpDelta.build_from_profile(employee.current_profile).save!
          employee.update_active_directory_account
          employee.save!
        end
      end
    end

    def process_rehire(event)
      json = JSON.parse(event.json)
      employee = Employee.find_by_employee_id(worker_id(json))

      if employee.present?
        profiler = EmployeeProfile.new
        updated_account = profiler.link_accounts(employee.id, event.id)
        employee.rehire!
      else
        EmployeeWorker.perform_async("Onboarding", event_id: event.id)
        return false
      end
    end

    def job_change?(e, term_date)
      date = DateTime.parse(term_date) + 1.day

      month = date.strftime("%m")
      day = date.strftime("%d")
      year = date.strftime("%Y")

      res = get_json_str("https://#{SECRETS.adp_api_domain}/hr/v2/workers/#{e.adp_assoc_oid}?asOfDate=#{month}%2F#{day}%2F#{year}")
      json = JSON.parse(res.body)

      adp_status = json.dig("workers", 0, "workerStatus", "statusCode", "codeValue")

      if adp_status != "Terminated"
        return true
      else
        return false
      end
    end

    def del_event(num)
      set_http("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages/#{num}")
      res = @http.delete(@uri.request_uri, {'Authorization' => "Bearer #{@token}"})
    end

    private

    def get_json_str(url)
      # overriding this method because events need access to the header info
      set_http(url)
      @http.get(@uri.request_uri, {'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}"})
    end

    def send_onboard_with_event(event)
      EmployeeWorker.perform_async("Onboarding", event_id: event.id)
    end

    def event_json_to_hash(json)
      worker_json = json.dig("events", 0, "data", "output", "worker")
      parser = WorkerJsonParser.new
      parser.gen_worker_hash(worker_json)
    end

    def is_rehire?(json)
      custom_indicators = json.dig("events", 0, "data", "output", "worker", "customFieldGroup", "indicatorFields")

      if custom_indicators.present?
        rehire_json = custom_indicators.find { |f| f["nameCode"]["codeValue"] == "Is this a Worker Type Change?"}
        rehire = rehire_json.try(:dig, "indicatorValue")
      end
      rehire == true
    end

    def kind(body)
      JSON.parse(body).dig("events", 0, "eventNameCode", "codeValue")
    end

    def redact_confidential_info(body)
      json = JSON.parse(body)
      if json.dig("events", 0, "data", "output", "worker", "person", "governmentIDs").present?
        json['events'][0]['data']['output']['worker']['person']['governmentIDs'].each do |government_id|
          government_id['idValue'] = "REDACTED"
        end
      elsif json.dig("events", 0, "data", "output", "worker", "person", "governmentID").present?
        json['events'][0]['data']['output']['worker']['person']['governmentID']['idValue'] = "REDACTED"
      end
      json
    end

    def is_retroactive?(e, emp_date)
      date = DateTime.parse(emp_date)
      hour = 21
      zone = e.nearest_time_zone
      emp_date_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
      emp_date_time <= DateTime.now.in_time_zone("UTC")
    end

    def worker_id(json)
      json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
    end

    def leave_date(json)
      json.dig("events", 0, "data", "output", "worker", "workerStatus", "effectiveDate")
    end

    def term_date(json)
      json.dig("events", 0, "data", "output", "worker", "workerDates", "terminationDate")
    end


  end
end
