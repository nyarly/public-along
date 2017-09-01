module AdpService
  class Worker < Base

    def update_worker_email(employee)
      url = "https://#{SECRETS.adp_api_domain}/events/hr/v1/worker.business-communication.email.change"
      @adp_assoc_oid = employee.adp_assoc_oid
      @adp_emp_id = employee.employee_id
      @email = employee.email

      if @email.present?
        update_response = get_json_str(url)
        json = JSON.parse(update_response)
        update_status = json.dig("events", 0, "eventStatusCode", "codeValue")

        if update_status == "complete"
          return true
        else
          Rails.logger.info "Could not update email for employee id #{@adp_emp_id} with #{@email}"
          return false
        end
      end
    end

    private

    def get_json_str(url)
      set_http(url)
      data = get_post_json
      request = Net::HTTP::Post.new(@uri.request_uri, {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}", 'roleCode' => 'practitioner', 'Accept-Language' => 'en-US'})
      request.content_type = 'application/json'
      request.body = data.to_json
      response = @http.request(request)

      Rails.logger.info "POST requst to update email on employee id #{@adp_emp_id} with #{@email}"
      Rails.logger.info response.code
      Rails.logger.info response.message
      response.body
    end

    def get_post_json
      {
        "events": [
          {
            "data": {
              "eventContext": {
                "worker": {
                  "associateOID": "#{@adp_assoc_oid}"
                }
              },
              "transform": {
                "worker": {
                  "businessCommunication": {
                    "email": {
                      "nameCode": {
                        "codeValue": "Work E-mail",
                        "shortName": "Work E-mail",
                      },
                      "emailUri": "#{@email}"
                    }
                  }
                }
              },
              "output": {
                "worker": {
                  "associateOID": "#{@adp_assoc_oid}",
                  "workerID": {
                    "idValue": "#{@adp_emp_id}"
                  },
                  "businessCommunication": {
                    "email": {
                      "nameCode": {
                        "codeValue": "Work E-mail",
                        "shortName": "Work E-mail"
                      },
                      "itemID": "#{@email}"
                    }
                  }
                }
              }
            }
          }
        ]
      }
    end
  end
end
