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
      ae = AdpEvent.new(
        json: body,
        msg_id: str.to_hash["adp-msg-msgid"][0],
        status: "New"
      )

      if ae.save
        sort_event(body, ae)
        return true
      else
        return false
      end
    end

    def sort_event(body, adp_event)
      json = JSON.parse(body)
      kind =  json.dig("events", 0, "eventNameCode", "codeValue")
      case kind
      when "worker.hire"
        if process_hire(json)
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
      end
      del_event(adp_event.msg_id)
    end

    def process_hire(json)
      parser = WorkerJsonParser.new
      worker_json = json.dig("events", 0, "data", "output", "worker")
      w_hash = parser.gen_worker_hash(worker_json)
      w_hash[:status] = "Pending" # put worker as "Pending" rather than "Active"
      e = Employee.new(w_hash)
      Employee.check_manager(e.manager_id)
      if e.save
        ads = ActiveDirectoryService.new
        ads.create_disabled_accounts([e])
        return true
      else
        return false
      end
    end

    def process_term(json)
      worker_id = json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
      term_date = json.dig("events", 0, "data", "output", "worker", "workerDates", "terminationDate")
      e = Employee.find_by(employee_id: worker_id)
      if e.present? && !job_change?(e, term_date)
        e.assign_attributes(termination_date: term_date)
        send_offboard_form(e)
      else
        return false
      end

      if e.present? && e.save
        ads = ActiveDirectoryService.new
        ads.update([e])
        return true
      else
        return false
      end
    end

    def process_leave(json)
      worker_id = json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
      leave_date = json.dig("events", 0, "data", "output", "worker", "workerStatus", "effectiveDate")
      e = Employee.find_by(employee_id: worker_id)
      e.assign_attributes(leave_start_date: leave_date) if e.present?

      if e.present? && e.save
        ads = ActiveDirectoryService.new
        ads.update([e])
        return true
      else
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

    def send_offboard_form(e)
      if Time.now < 5.business_days.before(e.termination_date)
        EmployeeWorker.perform_at(5.business_days.before(e.termination_date), "Offboarding", e.id)
      else
        EmployeeWorker.perform_async("Offboarding", e.id)
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
