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

      ae = AdpEvent.new(
        json: scrubbed_json,
        msg_id: str.to_hash["adp-msg-msgid"][0],
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
        add_basic_security_profile(e)
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
        delta = build_emp_delta(e)
        send_offboard_forms(e)
      else
        return false
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

    def process_leave(json)
      worker_id = json.dig("events", 0, "data", "output", "worker", "workerID", "idValue").downcase
      leave_date = json.dig("events", 0, "data", "output", "worker", "workerStatus", "effectiveDate")
      e = Employee.find_by(employee_id: worker_id)

      if e.present?
        e.assign_attributes(leave_start_date: leave_date)
        delta = build_emp_delta(e)
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

    def send_offboard_forms(e)
      TechTableMailer.offboard_notice(e).deliver_now
      EmployeeWorker.perform_async("Offboarding", e.id)
    end

    def del_event(num)
      set_http("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages/#{num}")
      res = @http.delete(@uri.request_uri, {'Authorization' => "Bearer #{@token}"})
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

    def add_basic_security_profile(employee)
      default_sec_group = ""

      if employee.worker_type.kind == "Regular"
        default_sec_group = SecurityProfile.find_by(name: "Basic Regular Worker Profile").id
      elsif employee.worker_type.kind == "Temporary"
        default_sec_group = SecurityProfile.find_by(name: "Basic Temp Worker Profile").id
      elsif employee.worker_type.kind == "Contractor"
        default_sec_group = SecurityProfile.find_by(name: "Basic Contract Worker Profile").id
      end

      emp_trans = EmpTransaction.new(
        kind: "Service",
        notes: "Initial provisioning by Mezzo"
      )

      emp_trans.emp_sec_profiles.build(security_profile_id: default_sec_group, employee_id: employee.id)

      emp_trans.save!

      if emp_trans.emp_sec_profiles.count > 0
        sas = SecAccessService.new(emp_trans)
        sas.apply_ad_permissions
      end
    end

    private

    def get_json_str(url)
      # overriding this method because events need access to the header info
      set_http(url)
      @http.get(@uri.request_uri, {'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}"})
    end
  end
end
