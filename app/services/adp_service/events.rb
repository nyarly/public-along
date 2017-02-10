module AdpService
  class Events < Base

    def events
      str = get_json_str("https://#{SECRETS.adp_api_domain}/core/v1/event-notification-messages")
      body = str.body
      if body.present?
        ae = AdpEvent.new(
          json: body,
          msg_id: str.to_hash["adp-msg-msgid"][0],
          status: "New"
        )
        ae.save
        json = JSON.parse(body)
        kind =  json.dig("events", 0, "eventNameCode", "codeValue")
        if kind == "worker.hire"
          parser = WorkerJsonParser.new
          worker_json = json.dig("events", 0, "data", "output", "worker")
          w_hash = parser.gen_worker_hash(worker_json)
          # puts w_hash
          e = Employee.new(w_hash)
          # puts e.inspect
          if e.save
            ads = ActiveDirectoryService.new
            ads.create_disabled_accounts([e])
          end
          # put employee in correct state and send onboarding form
        end

        # del_event(ae.msg_id) if ae.save
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
