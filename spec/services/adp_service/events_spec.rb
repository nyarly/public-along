
require 'rails_helper'

describe AdpService::Events, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:header_hash) { {"server"=>["Apache-Coyote/1.1"], "adp-correlationid"=>["ac5c8427-d7df-4a36-9c1c-ed9a9405e58f"], "content-language"=>["en-US"], "adp-msg-msgid"=>["0x_414d51205554494e464f4251362020206f3e8b5866814928"], "etag"=>["W/\"298-3FGDAYibwmNEuawCuC+BEg\""], "x-upstream"=>["10.136.1.43:4110"], "strict-transport-security"=>["max-age=31536000"], "content-type"=>["application/json;charset=utf-8"], "content-length"=>["664"], "date"=>["Fri, 10 Feb 2017 00:57:40 GMT"], "connection"=>["close"]} }
  let(:json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_event.json") }
  let(:hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_hire_event.json") }
  let(:contract_hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_contract_hire_event.json") }
  let(:term_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_terminate_event.json") }
  let(:leave_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_leave_event.json") }

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
    expect(response).to receive(:body).once.and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  it "should get a bearer token from ADP" do
    expect(AdpService::Events.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe "events" do

    let!(:worker_type_1) { FactoryGirl.create(:worker_type, name: "Contractor", code: "CONT") }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: "Regular Full-Time", code: "OLFR") }
    let(:ads) { double(ActiveDirectoryService) }

    before :each do
      allow(URI).to receive(:parse).with("https://api.adp.com/core/v1/event-notification-messages").and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    describe "get_events" do
      it "should process event if body is present and call itself until nil" do
        expect(response).to receive(:body).ordered.and_return(json)
        expect(response).to receive(:body).ordered.and_return(json)
        expect(response).to receive(:body).ordered.and_return(nil)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_event).twice.and_return(true)
        expect(adp).to receive(:get_events).exactly(3).times.and_call_original

        adp.get_events
      end

      it "should return false if response is nil" do
        expect(response).to receive(:body).ordered.and_return(nil)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to_not receive(:process_event)
        expect(adp.get_events).to eq(false)
      end
    end

    describe "process_event" do
      let(:ae) { double(AdpEvent) }

      it "should create AdpEvent with correct values" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:sort_event)
        expect{
          adp.process_event(header_hash, json)
        }.to change{AdpEvent.count}.from(0).to(1)
        expect(AdpEvent.last.json).to eq(json)
        expect(AdpEvent.last.msg_id).to eq("0x_414d51205554494e464f4251362020206f3e8b5866814928")
        expect(AdpEvent.last.status).to eq("New")
      end

      it "should return false if AdpEvent does not save" do
        allow(AdpEvent).to receive(:new).and_return(ae)
        allow(ae).to receive(:save).and_return(false)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to_not receive(:sort_event)
        expect(adp.process_event(header_hash, json)).to eq(false)
      end
    end

    describe "sort_event" do
      let(:adp_event) { FactoryGirl.create(:adp_event) }

      it "should process hire for new hire" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_hire).and_return(true)
        expect(adp).to receive(:del_event).with(adp_event.msg_id)
        expect(adp_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(hire_json, adp_event)
      end

      it "should process hire for contract hire" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_hire).and_return(true)
        expect(adp).to receive(:del_event).with(adp_event.msg_id)
        expect(adp_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(contract_hire_json, adp_event)
      end

      it "should process term for term" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_term).and_return(true)
        expect(adp).to receive(:del_event).with(adp_event.msg_id)
        expect(adp_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(term_json, adp_event)
      end

      it "should process leave for leave" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_leave).and_return(true)
        expect(adp).to receive(:del_event).with(adp_event.msg_id)
        expect(adp_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(leave_json, adp_event)
      end

      it "should delete event for anything else" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:del_event).with(adp_event.msg_id)

        adp.sort_event(json, adp_event)
      end
    end

    describe "hire event" do
      let(:parsed_reg_json) { JSON.parse(hire_json) }
      let(:parsed_contract_json) { JSON.parse(contract_hire_json) }

      it "should create Employee w/ pending status if regular hire event" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:check_manager)
        expect{
          adp.process_hire(parsed_reg_json)
        }.to change{Employee.count}.from(0).to(1)
        expect(Employee.last.employee_id).to eq("if0rcdig4")
        expect(Employee.last.status).to eq("Pending")
      end

      it "should make indicated manager if not already a manager" do
        manager_to_be = FactoryGirl.create(:employee, employee_id: "100449")
        sp = FactoryGirl.create(:security_profile, name: "Basic Manager")

        expect(ActiveDirectoryService).to receive(:new).twice.and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_hire(parsed_reg_json)
        }.to change{Employee.managers.include?(manager_to_be)}.from(false).to(true)
      end

      it "should do nothing if manager is already mgr in mezzo" do
        manager = FactoryGirl.create(:employee, employee_id: "100449")
        sp = FactoryGirl.create(:security_profile, name: "Basic Manager")
        manager.security_profiles << sp

        expect(ActiveDirectoryService).to receive(:new).once.and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(Employee.managers.include?(manager)).to eq(true)
        expect{
          adp.process_hire(parsed_reg_json)
        }.to_not change{Employee.managers.include?(manager)}
      end

      it "should have worker end date if contract hire event" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:check_manager)
        expect{
          adp.process_hire(parsed_contract_json)
        }.to change{Employee.count}.from(0).to(1)
        expect(Employee.last.employee_id).to eq("8vheos3zl")
        expect(Employee.last.status).to eq("Pending")
        expect(Employee.last.contract_end_date).to eq("2017-12-01")
      end
    end

    describe "termination event" do
      let!(:term_emp) { FactoryGirl.create(:employee, employee_id: "101652", termination_date: nil) }
      let(:parsed_json) { JSON.parse(term_json) }

      it "should update termination date" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)
        expect(EmployeeWorker).to receive(:perform_async)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_term(parsed_json)
        }.to_not change{Employee.count}
        expect(term_emp.reload.termination_date).to eq("2017-01-24")
      end
    end

    describe "leave event" do
      let!(:leave_emp) { FactoryGirl.create(:employee, employee_id: "100344", leave_start_date: nil) }
      let(:parsed_json) { JSON.parse(leave_json) }

      it "should update leave date" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_leave(parsed_json)
        }.to_not change{Employee.count}
        expect(leave_emp.reload.leave_start_date).to eq("2017-01-23")
      end
    end

    describe "check leave return" do
      let!(:leave_emp) {FactoryGirl.create(:employee, status: "Inactive", adp_assoc_oid: "123456", leave_return_date: nil) }
      let!(:leave_cancel_emp) {FactoryGirl.create(:employee, status: "Inactive", adp_assoc_oid: "123457", leave_return_date: Date.today + 2.days) }
      let!(:do_nothing_emp) {FactoryGirl.create(:employee, status: "Inactive", adp_assoc_oid: "123458", leave_return_date: nil) }
      let!(:future_date) { 1.day.from_now.change(:usec => 0) }

      before :each do
        expect(URI).to receive(:parse).ordered.with("https://api.adp.com/hr/v2/workers/123456?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).ordered.and_return(
          '{"workers": [
            {
              "workerStatus": {
                "statusCode": {
                  "codeValue": "Active"
                }
              }
            }
          ]}'
        )
        expect(URI).to receive(:parse).ordered.with("https://api.adp.com/hr/v2/workers/123457?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).ordered.and_return(
          '{"workers": [
            {
              "workerStatus": {
                "statusCode": {
                  "codeValue": "Inactive"
                }
              }
            }
          ]}'
        )
        expect(URI).to receive(:parse).ordered.with("https://api.adp.com/hr/v2/workers/123458?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).ordered.and_return(
          '{"workers": [
            {
              "workerStatus": {
                "statusCode": {
                  "codeValue": "Inactive"
                }
              }
            }
          ]}'
        )
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
      end

      it "should update leave return date and call AD update, if applicable" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update).with([leave_emp, leave_cancel_emp])

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.check_leave_return
        }.to_not change{Employee.count}
        expect(leave_emp.reload.leave_return_date).to eq(future_date)
        expect(leave_cancel_emp.reload.leave_return_date).to eq(nil)
        expect(do_nothing_emp.reload.leave_return_date).to eq(nil)
      end
    end
  end
end
