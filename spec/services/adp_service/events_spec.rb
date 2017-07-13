
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
  let(:json) { JSON.dump(JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_event.json"))) }
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

    let!(:worker_type_1) { FactoryGirl.create(:worker_type, name: "Contractor", code: "CONT", kind: "Contractor") }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: "Regular Full-Time", code: "OLFR", kind: "Regular") }
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

      it "should scrub sensitive data" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:sort_event)
        expect{
          adp.process_event(header_hash, hire_json)
        }.to change{AdpEvent.count}.from(0).to(1)
        expect(
          JSON.parse(AdpEvent.last.json)['events'][0]['data']['output']['worker']['person']['governmentIDs'][0]['idValue']
        ).to eq("REDACTED")
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
      let(:application) { FactoryGirl.create(:application, name: "Security Group") }
      let(:regular_al) { FactoryGirl.create(:access_level, name: "OT Regular Workers", application_id: application.id) }
      let!(:regular_sp) { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
      let!(:contract_sp) { FactoryGirl.create(:security_profile, name: "Basic Contract Worker Profile") }
      let!(:regular_spal) { FactoryGirl.create(:sec_prof_access_level, security_profile_id: regular_sp.id, access_level_id: regular_al.id) }
      let(:sas) { double(SecAccessService) }


      before :each do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        expect(sas).to receive(:apply_ad_permissions)
        expect(SecAccessService).to receive(:new).and_return(sas)
      end

      it "should create Employee w/ pending status if regular hire event" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(Employee).to receive(:check_manager)

        expect{
          adp.process_hire(parsed_reg_json)
        }.to change{Employee.count}.from(0).to(1)
        expect(Employee.last.employee_id).to eq("if0rcdig4")
        expect(Employee.last.status).to eq("Pending")
      end

      it "should make indicated manager if not already a manager" do
        manager_to_be = FactoryGirl.create(:employee, employee_id: "100449")
        sp = FactoryGirl.create(:security_profile, name: "Basic Manager")
        al = FactoryGirl.create(:access_level)
        sp_al = FactoryGirl.create(:sec_prof_access_level, security_profile_id: sp.id, access_level_id: al.id)

        expect(SecAccessService).to receive(:new).and_return(sas)
        expect(sas).to receive(:apply_ad_permissions)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_hire(parsed_reg_json)
        }.to change{Employee.managers.include?(manager_to_be)}.from(false).to(true)
      end

      it "should do nothing if manager is already mgr in mezzo" do
        manager = FactoryGirl.create(:employee, employee_id: "100449")
        sp = FactoryGirl.create(:security_profile, name: "Basic Manager")
        emp_transaction = FactoryGirl.create(:emp_transaction,
          employee_id: manager.id)
        FactoryGirl.create(:emp_sec_profile,
          security_profile_id: sp.id,
          emp_transaction_id: emp_transaction.id)

        expect(sas).to_not receive(:apply_ad_permissions)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(Employee.managers.include?(manager)).to eq(true)
        expect{
          adp.process_hire(parsed_reg_json)
        }.to_not change{Employee.managers.include?(manager)}
      end

      it "should have worker end date if contract hire event" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(Employee).to receive(:check_manager)
        expect{
          adp.process_hire(parsed_contract_json)
        }.to change{Employee.count}.from(0).to(1)
        expect(Employee.last.employee_id).to eq("8vheos3zl")
        expect(Employee.last.status).to eq("Pending")
        expect(Employee.last.contract_end_date).to eq("2017-12-01")
      end

      it "should add the user to the default security group for their worker type" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(Employee).to receive(:check_manager)
        expect{
          adp.process_hire(parsed_reg_json)
        }.to change{Employee.count}.from(0).to(1)
        expect(Employee.last.reload.active_security_profiles[0]).to eq(regular_sp)
        expect(Employee.last.reload.active_security_profiles[0].access_levels[0]).to eq(regular_al)
      end
    end

    describe "termination event" do
      let!(:term_emp) { FactoryGirl.create(:employee, employee_id: "101652", termination_date: nil) }
      let(:parsed_json) { JSON.parse(term_json) }
      let(:mailer) { double(TechTableMailer) }

      it "should update termination date" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)
        expect(TechTableMailer).to receive(:offboard_notice).and_return(mailer)
        expect(mailer).to receive(:deliver_now)
        expect(EmployeeWorker).to receive(:perform_async)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:job_change?).and_return(false)
        expect{
          adp.process_term(parsed_json)
        }.to_not change{Employee.count}
        expect(term_emp.reload.termination_date).to eq("2017-01-24")
        expect(term_emp.emp_deltas.last.before).to eq({"termination_date"=>nil})
        expect(term_emp.emp_deltas.last.after).to eq({"termination_date"=>"2017-01-24 00:00:00 UTC"})
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
        expect(leave_emp.emp_deltas.last.before).to eq({"leave_start_date"=>nil})
        expect(leave_emp.emp_deltas.last.after).to eq({"leave_start_date"=>"2017-01-23 00:00:00 UTC"})
      end
    end
  end
end
