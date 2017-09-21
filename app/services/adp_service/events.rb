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
      json = JSON.parse(body)
      if json.dig("events", 0, "data", "output", "worker", "person", "governmentIDs").present?
        json['events'][0]['data']['output']['worker']['person']['governmentIDs'].each do |government_id|
          government_id['idValue'] = "REDACTED"
        end
      elsif json.dig("events", 0, "data", "output", "worker", "person", "governmentID").present?
        json['events'][0]['data']['output']['worker']['person']['governmentID']['idValue'] = "REDACTED"
      end
      scrubbed_json = JSON.dump(json)
      kind = json.dig("events", 0, "eventNameCode", "codeValue")

      ae = AdpEvent.new(
        json: scrubbed_json,
        msg_id: str.to_hash["adp-msg-msgid"][0],
        kind: kind,
        status: "New"
      )

      if ae.save
        sort_event(scrubbed_json, ae)
        return true
      else
        return false
      end
    end

    def sort_event(body, adp_event)
      json = JSON.parse(body)

      case adp_event.kind
      when "worker.hire"
        if process_hire(json, adp_event)
          adp_event.update_attributes(status: "Processed")
        end
      when "worker.terminate"
        if process_term(json)
          adp_event.update_attributes(status: "Processed")
        end
      when "worker.on-leave"
        if process_leave(json)
          adp_event.update_attributes(status: "Processed")
        end
      when "worker.rehire"
        if process_rehire(json, adp_event)
          adp_event.update_attributes(status: "Processed")
        end
      end
      del_event(adp_event.msg_id)
    end

    def process_hire(json, event)
      worker_json = json.dig("events", 0, "data", "output", "worker")
      custom_indicators = json.dig("events", 0, "data", "output", "worker", "customFieldGroup", "indicatorFields")

      if custom_indicators.present?
        rehire_json = custom_indicators.find { |f| f["nameCode"]["codeValue"] == "Is this a Worker Type Change?"}
        rehire = rehire_json.try(:dig, "indicatorValue")
      end

      if rehire.present? and rehire == true
        parser = WorkerJsonParser.new
        worker_hash = parser.gen_worker_hash(worker_json)

        if worker_hash[:manager_id].present?
          EmployeeWorker.perform_async("Onboarding", event_id: event.id)
          return false
        else
          return false
        end
      else
        profiler = EmployeeProfile.new
        employee = profiler.new_employee(event)
        employee.hire!
      end
    end

    def process_term(json)
      worker_id = json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
      term_date = json.dig("events", 0, "data", "output", "worker", "workerDates", "terminationDate")
      e = Employee.find_by_employee_id(worker_id)
      profile = e.current_profile

      if e.present? && !job_change?(e, term_date)
        e.assign_attributes(termination_date: term_date)
        profile.assign_attributes(end_date: term_date)

        if is_retroactive?(e, term_date)
          process_retro_term(e, profile)
        else
          delta = EmpDelta.build_from_profile(profile)

          if e.save and profile.save
            ads = ActiveDirectoryService.new
            ads.update([e])
            delta.save if delta.present?
            profile.request_manager_action!
          else
            return false
          end
        end
      end
    end

    def process_retro_term(e, profile)
      e.terminate

      delta = EmpDelta.build_from_profile(profile)

      if e.save!
        TechTableMailer.offboard_instructions(e).deliver_now

        delta.save if delta.present?
        return true
      end
    end

    def is_retroactive?(e, term_date)
      date = DateTime.parse(term_date)
      hour = 21
      zone = e.nearest_time_zone
      term_date_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
      term_date_time <= DateTime.now.in_time_zone("UTC")
    end

    def process_leave(json)
      worker_id = json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
      leave_date = json.dig("events", 0, "data", "output", "worker", "workerStatus", "effectiveDate")
      e = Employee.find_by_employee_id(worker_id)
      profile = e.current_profile

      if e.present?
        e.assign_attributes(leave_start_date: leave_date)
        delta = EmpDelta.build_from_profile(profile)
      end

      if e.present? && e.save
        ads = ActiveDirectoryService.new
        ads.update([e])
        delta.save if delta.present?
        return true
      else
        return false
      end
    end

    def process_rehire(json, event)
      rehire_event = event
      worker_id = json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
      e = Employee.find_by_employee_id(worker_id)

      if e.present?
        profiler = EmployeeProfile.new
        updated_account = profiler.link_accounts(e.id, rehire_event.id)
        updated_account.save!
        e.rehire!
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
  end
end
