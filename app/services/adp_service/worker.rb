module AdpService
  class Worker < Base

    def update_worker_email(employee)
      url = "https://#{SECRETS.adp_api_domain}/events/hr/v1/worker.business-communication.email.change"

      if employee.email.present?
        update_response = post_json_str(url, employee)
        json = JSON.parse(update_response)
        update_status = json.dig("events", 0, "eventStatusCode", "codeValue")

        if update_status == "complete"
          return true
        else
          Rails.logger.info "Could not update email for employee id #{employee.employee_id} with #{employee.email}"
          return false
        end
      end
    end

    private

    def post_json_str(url, employee)
      set_http(url)
      data = get_post_json(employee)
      request = Net::HTTP::Post.new(@uri.request_uri, {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}", 'roleCode' => 'practitioner', 'Accept-Language' => 'en-US'})
      request.content_type = 'application/json'
      request.body = data.to_json
      response = @http.request(request)

      Rails.logger.info "POST requst to update email on employee id #{employee.employee_id} with #{employee.email}"
      Rails.logger.info response.code
      Rails.logger.info response.message
      response.body
    end

    def get_post_json(employee)
      {
        "events": [
          {
            "data": {
              "eventContext": {
                "worker": {
                  "associateOID": "#{employee.adp_assoc_oid}"
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
                      "emailUri": "#{employee.email}"
                    }
                  }
                }
              },
              "output": {
                "worker": {
                  "associateOID": "#{employee.adp_assoc_oid}",
                  "workerID": {
                    "idValue": "#{employee.employee_id}"
                  },
                  "businessCommunication": {
                    "email": {
                      "nameCode": {
                        "codeValue": "Work E-mail",
                        "shortName": "Work E-mail"
                      },
                      "itemID": "#{employee.email}"
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
