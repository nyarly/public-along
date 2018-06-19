module AdpService
  class Events < Base

    def get_events
      str = get_json_str("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages")
      body = str.body

      return false unless body.present?
      get_events if process_event(str, body)
    end

    def process_event(str, body)
      event_body = JSON.dump(redact_confidential_info(body))

      ae = AdpEvent.new(
        json: event_body,
        msg_id: str.to_hash['adp-msg-msgid'][0],
        kind: kind(event_body)
      )

      return false unless ae.save
      sort_event(ae)
      true
    end

    def sort_event(adp_event)
      case adp_event.kind
      when 'worker.hire'
        adp_event.process! if process_hire(adp_event)
      when 'worker.terminate'
        adp_event.process! if process_term(adp_event)
      when 'worker.on-leave'
        adp_event.process! if process_leave(adp_event)
      when 'worker.rehire'
        adp_event.process! if process_rehire(adp_event)
      end
      del_event(adp_event.msg_id)
    end

    def process_hire(event)
      json = JSON.parse(event.json)

      if rehire?(json)
        worker_hash = event_json_to_hash(json)

        # If this event comes over as a rehire,
        # don't immediately create a new employee record.
        # Send the onboarding form to the manager with the event,
        # so they have an opportunity to link accounts.
        send_onboard_form_with_event(event) unless worker_hash[:manager_id].blank?
        return false
      else
        profiler = EmployeeProfile.new
        employee = profiler.new_employee(event)
        employee.hire!
        onboard = EmployeeService::Onboard.new(employee)
        onboard.new_worker
        onboard.send_manager_form
      end
    end

    def process_term(event)
      json = JSON.parse(event.json)
      term_date = term_date(json)
      employee = Employee.find_by_employee_id(worker_id(json))

      # Don't process this event if you can't find the employee
      # This basically only happens if P&C terminates a test account
      # + Don't process the termination if it's a job change
      return false if employee.blank? || job_change?(employee, term_date)

      assign_term_date(employee, term_date)

      return true if OffboardPolicy.new(employee).offboarded_contractor?
      return process_retro_term(employee) if retroactive?(employee, term_date)

      return true if employee.completed?

      employee.start_offboard_process!
    end

    def assign_term_date(employee, term_date)
      employee.assign_attributes(termination_date: term_date)
      employee.current_profile.assign_attributes(end_date: term_date)
      delta = EmpDelta.build_from_profile(employee.current_profile)
      delta.save! if delta.present?
      employee.current_profile.save! && employee.save!
    end

    def process_retro_term(employee)
      employee.terminate_immediately!
    end

    def process_leave(event)
      json = JSON.parse(event.json)
      employee = Employee.find_by_employee_id(worker_id(json))

      # Don't process this event if you can't find the employee
      # This basically only happens if P&C operates on a test account
      return false if employee.blank?

      leave_date = leave_date(json)
      employee.assign_attributes(leave_start_date: leave_date)
      EmpDelta.build_from_profile(employee.current_profile).save!
      employee.save!
      employee.start_leave! if retroactive?(employee, leave_date)
    end

    def process_rehire(event)
      json = JSON.parse(event.json)
      employee = Employee.find_by_employee_id(worker_id(json))

      # If this event comes over as a rehire,
      # don't immediately create a new employee record.
      # Send the onboarding form to the manager with the event,
      # so they have an opportunity to link accounts.
      return send_onboard_form_with_event(event) if employee.blank?

      profiler = EmployeeProfile.new
      profiler.link_accounts(employee.id, event.id)
      employee.hire!
      onboard = EmployeeService::Onboard.new(employee)
      onboard.re_onboard
      onboard.send_manager_form
    end

    def job_change?(e, term_date)
      date = Date.parse(term_date) + 1.day
      month = date.strftime('%m')
      day = date.strftime('%d')
      year = date.strftime('%Y')
      worker_url = "https://#{SECRETS.adp_api_domain}/hr/v2/workers/#{e.adp_assoc_oid}?asOfDate=#{month}%2F#{day}%2F#{year}"

      res = get_json_str(worker_url)
      json = JSON.parse(res.body)

      adp_status = json.dig('workers', 0, 'workerStatus', 'statusCode', 'codeValue')

      return true if adp_status != 'Terminated'
      false
    end

    def del_event(num)
      set_http("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages/#{num}")
      @http.delete(@uri.request_uri, 'Authorization' => "Bearer #{@token}")
    end

    private

    def get_json_str(url)
      # overriding this method because events need access to the header info
      set_http(url)
      @http.get(@uri.request_uri, 'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}")
    end

    def send_onboard_form_with_event(event)
      EmployeeWorker.perform_async('job_change', event_id: event.id)
    end

    def event_json_to_hash(json)
      worker_json = json.dig('events', 0, 'data', 'output', 'worker')
      parser = WorkerJsonParser.new
      parser.gen_worker_hash(worker_json)
    end

    def rehire?(json)
      custom_indicators = json.dig('events', 0, 'data', 'output', 'worker', 'customFieldGroup', 'indicatorFields')

      if custom_indicators.present?
        rehire_json = custom_indicators.find { |f| f['nameCode']['codeValue'] == 'Is this a Worker Type Change?' }
        rehire = rehire_json.try(:dig, 'indicatorValue')
      end
      rehire == true
    end

    def kind(body)
      JSON.parse(body).dig('events', 0, 'eventNameCode', 'codeValue')
    end

    def redact_confidential_info(body)
      json = JSON.parse(body)
      if json.dig('events', 0, 'data', 'output', 'worker', 'person', 'governmentIDs').present?
        json['events'][0]['data']['output']['worker']['person']['governmentIDs'].each do |government_id|
          government_id['idValue'] = 'REDACTED'
        end
      elsif json.dig('events', 0, 'data', 'output', 'worker', 'person', 'governmentID').present?
        json['events'][0]['data']['output']['worker']['person']['governmentID']['idValue'] = 'REDACTED'
      end
      json
    end

    def retroactive?(e, emp_date)
      date = Date.parse(emp_date)
      hour = 21
      zone = e.nearest_time_zone
      emp_date_time = ActiveSupport::TimeZone.new(zone).local_to_utc(Time.new(date.year, date.month, date.day, hour))
      emp_date_time <= Time.now.in_time_zone('UTC')
    end

    def worker_id(json)
      json.dig('events', 0, 'data', 'output', 'worker', 'workerID', 'idValue').downcase
    end

    def leave_date(json)
      json.dig('events', 0, 'data', 'output', 'worker', 'workerStatus', 'effectiveDate')
    end

    def term_date(json)
      json.dig('events', 0, 'data', 'output', 'worker', 'workerDates', 'terminationDate')
    end
  end
end
