require 'rails_helper'

describe AdpService::Worker, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:update_url)  { "https://#{SECRETS.adp_api_domain}/events/hr/v1/worker.business-communication.email.change" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:post_req)    { double(Net::HTTP::Post) }
  let(:response)    { double(Net::HTTPResponse) }
  let!(:employee)    { FactoryGirl.create(:employee,
                      email: "ggarbo@example.com")}
  let!(:profile)    { FactoryGirl.create(:profile,
                      employee: employee,
                      profile_status: "Active",
                      adp_assoc_oid: "qwerty12345",
                      adp_employee_id: "123456")}

  before :each do
    allow(uri).to receive(:host).and_return(host)
    allow(uri).to receive(:port).and_return(port)
    allow(uri).to receive(:request_uri).and_return(request_uri)
    allow(http).to receive(:cert=)
    allow(http).to receive(:key=)
    allow(OpenSSL::X509::Certificate).to receive(:new)
    allow(OpenSSL::PKey::RSA).to receive(:new)

    allow(URI).to receive(:parse).with(url).and_return(uri)
    allow(Net::HTTP).to receive(:new).with(host, port).and_return(http).at_least(:once)
    allow(http).to receive(:read_timeout=).with(200).at_least(:once)
    allow(http).to receive(:use_ssl=).with(true).at_least(:once)
    allow(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER).at_least(:once)
    allow(http).to receive(:post).with(
      request_uri,
      '',
      { "Accept"=>"application/json",
        "Authorization"=>"Basic #{SECRETS.adp_creds}",
      }).and_return(response)
    expect(response).to receive(:body).and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  it "should get a bearer token from ADP" do
    expect(AdpService::Worker.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe "update worker email" do
    let(:request_body) {
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
    }

    it "should call parse json response, find status " do
      success_json = '{"events":[{"eventStatusCode":{"codeValue":"complete","shortName":"complete"},"data":{"eventContext":{"worker":{"associateOID":"qwerty12345"}},"output":{"worker":{"businessCommunication":{"email":{"nameCode":{"codeValue":"Work E-mail","shortName":"Work E-mail"},"emailUri":"ggarbo@example.com"}}}}}}]}'
      worker = AdpService::Worker.new
      worker.token = "a-token-value"

      expect(URI).to receive(:parse).with(update_url).and_return(uri)
      expect(Net::HTTP::Post).to receive(:new).with(request_uri,
        {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'Authorization' => "Bearer #{worker.token}", 'roleCode' => 'practitioner', 'Accept-Language' => 'en-US'}
        ).and_return(post_req)
      expect(post_req).to receive(:content_type=).with('application/json')
      expect(post_req).to receive(:body=).with(request_body.to_json)
      expect(http).to receive(:request).with(post_req).and_return(response)
      expect(response).to receive(:code)
      expect(response).to receive(:message)
      expect(response).to receive(:body).and_return(success_json)
      expect(worker.update_worker_email(employee)).to eq(true)
    end
  end
end
