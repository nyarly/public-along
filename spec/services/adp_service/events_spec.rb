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
  let(:json)        { JSON.dump(JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_event.json"))) }
  let(:hire_json)   { File.read(Rails.root.to_s+"/spec/fixtures/adp_hire_event.json") }
  let(:contract_hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_contract_hire_event.json") }
  let(:term_json)   { File.read(Rails.root.to_s+"/spec/fixtures/adp_terminate_event.json") }
  let(:leave_json)  { File.read(Rails.root.to_s+"/spec/fixtures/adp_leave_event.json") }
  let(:rehire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
  let(:cat_change_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_cat_change_hire_event.json") }

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
      let(:adp_event)           { FactoryGirl.create(:adp_event, json: JSON.dump(json)) }
      let(:hire_event)          { FactoryGirl.create(:adp_event, kind: "worker.hire") }
      let(:contract_hire_event) { FactoryGirl.create(:adp_event,
                                  kind: "worker.hire",
                                  json: JSON.dump(contract_hire_json)) }
      let(:term_event)          { FactoryGirl.create(:adp_event,
                                  kind: "worker.terminate",
                                  json: JSON.dump(term_json)) }
      let(:leave_event)         { FactoryGirl.create(:adp_event,
                                  kind: "worker.on-leave",
                                  json: JSON.dump(leave_json)) }

      it "should process hire for new hire" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_hire).and_return(true)
        expect(adp).to receive(:del_event).with(hire_event.msg_id)
        expect(hire_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(hire_event)
      end

      it "should process hire for contract hire" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_hire).and_return(true)
        expect(adp).to receive(:del_event).with(contract_hire_event.msg_id)
        expect(contract_hire_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(contract_hire_event)
      end

      it "should process term for term" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_term).and_return(true)
        expect(adp).to receive(:del_event).with(term_event.msg_id)
        expect(term_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(term_event)
      end

      it "should process leave for leave" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:process_leave).and_return(true)
        expect(adp).to receive(:del_event).with(leave_event.msg_id)
        expect(leave_event).to receive(:update_attributes).with(status: "Processed")

        adp.sort_event(leave_event)
      end

      it "should delete event for anything else" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect(adp).to receive(:del_event).with(adp_event.msg_id)

        adp.sort_event(adp_event)
      end
    end

    describe "hire event" do
      let!(:worker_type)      { FactoryGirl.create(:worker_type,
                                code: "OLFR",
                                kind: "Regular") }
      let!(:cont_worker_type) { FactoryGirl.create(:worker_type,
                                code: "CONT",
                                kind: "Contractor") }
      let(:application)       { FactoryGirl.create(:application,
                                name: "Security Group") }
      let(:regular_al)        { FactoryGirl.create(:access_level,
                                name: "OT Regular Workers",
                                application_id: application.id) }
      let!(:regular_sp)       { FactoryGirl.create(:security_profile,
                                name: "Basic Regular Worker Profile") }
      let!(:contract_sp)      { FactoryGirl.create(:security_profile,
                                name: "Basic Contract Worker Profile") }
      let!(:regular_spal)     { FactoryGirl.create(:sec_prof_access_level,
                                security_profile_id: regular_sp.id,
                                access_level_id: regular_al.id) }
      let(:sec_access_service){ double(SecAccessService) }
      let(:manager)           { FactoryGirl.create(:active_employee) }
      let!(:manager_profile)  { FactoryGirl.create(:active_profile,
                                employee: manager,
                                adp_employee_id: "654321") }
      let(:onboard_service)   { double(OnboardNewWorkerService) }

      before :each do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        expect(OnboardNewWorkerService).to receive(:new).and_return(onboard_service)
        expect(onboard_service).to receive(:process!)
      end

      it "should create Employee w/ pending status if regular hire event" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"
        event = FactoryGirl.create(:adp_event,
          status: "New",
          json: hire_json
        )

        expect{
          adp.process_hire(event)
        }.to change{Employee.count}.by(1)
        expect(Employee.reorder(:created_at).last.employee_id).to eq("if0rcdig4")
        expect(Employee.reorder(:created_at).last.status).to eq("pending")
      end

      it "should have worker end date if contract hire event" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        event = FactoryGirl.create(:adp_event,
          status: "New",
          json: contract_hire_json
        )

        expect{
          adp.process_hire(event)
        }.to change{Employee.count}.by(1)
        expect(Employee.reorder(:created_at).last.employee_id).to eq("8vheos3zl")
        expect(Employee.reorder(:created_at).last.status).to eq("pending")
        expect(Employee.reorder(:created_at).last.contract_end_date).to eq("2017-12-01")
      end
    end

    describe "hire event with category or rehire change indicator true" do
      let!(:acw_wt)          { FactoryGirl.create(:worker_type, code: "ACW") }
      let!(:regular_sp)      { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
      let(:manager)          { FactoryGirl.create(:active_employee) }
      let!(:manager_profile) { FactoryGirl.create(:active_profile,
                               employee: manager,
                               adp_employee_id: "101836") }

      it "should not create a new employee" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        event = FactoryGirl.create(:adp_event,
          status: "New",
          json: cat_change_json
        )

        expect{
          adp.process_hire(event)
        }.not_to change{Employee.count}
        expect(event.status).to eq("New")
      end

      it "should generate an onboarding form with the event" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        event = FactoryGirl.create(:adp_event,
          status: "New",
          json: cat_change_json
        )
        expect(EmployeeWorker).to receive(:perform_async)
        expect{
          adp.process_hire(event)
        }.not_to change{Employee.count}
      end
    end

    describe "termination event" do
      let!(:term_emp) { FactoryGirl.create(:active_employee, termination_date: nil) }
      let!(:profile)  { FactoryGirl.create(:active_profile,
                        employee: term_emp,
                        adp_employee_id: "101652") }
      let(:mailer)    { double(TechTableMailer) }
      let!(:event)    { FactoryGirl.create(:adp_event,
                        kind: "worker.terminate",
                        json: term_json) }

      before :each do
        Timecop.freeze(Time.new(2017, 1, 1, 1, 0, 0))
      end

      after :each do
        Timecop.return
      end

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
          adp.process_term(event)
        }.to_not change{Employee.count}
        expect(term_emp.reload.termination_date).to eq("2017-01-24")
        expect(term_emp.emp_deltas.last.before).to eq({"end_date"=>nil, "termination_date"=>nil})
        expect(term_emp.emp_deltas.last.after).to eq({"end_date"=>"2017-01-24 00:00:00 UTC", "termination_date"=>"2017-01-24 00:00:00 UTC"})
      end
    end

    describe "termination event should continue if employee not found" do
      let!(:event)    { FactoryGirl.create(:adp_event,
                        kind: "worker.terminate",
                        json: term_json) }


      it "should save the event and return" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_term(event)
        }.to_not change{Employee.count}
      end
    end

    describe "retroactive termination" do
      let(:manager)   { FactoryGirl.create(:active_employee) }
      let!(:term_emp) { FactoryGirl.create(:active_employee,
                        termination_date: nil,
                        manager: manager) }
      let!(:profile)  { FactoryGirl.create(:active_profile,
                        employee: term_emp,
                        adp_employee_id: "101652") }
      let(:mailer)    { double(TechTableMailer) }
      let(:offboard)  { double(OffboardingService) }
      let(:event)     { FactoryGirl.create(:adp_event, kind: "worker.terminate", json: term_json) }

      it "should update termination date, status, deactivate AD, send TT instructions" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:deactivate).with([term_emp])
        expect(TechTableMailer).to receive(:offboard_instructions).and_return(mailer)
        expect(mailer).to receive(:deliver_now)
        expect(OffboardingService).to receive(:new).and_return(offboard)
        expect(offboard).to receive(:offboard).with([term_emp])

        adp = AdpService::Events.new
        adp.token = "a-token-value"
        expect(adp).to receive(:job_change?).and_return(false)

        expect{
          adp.process_term(event)
        }.to_not change{Employee.count}
        expect(term_emp.reload.termination_date).to eq("2017-01-24")
        expect(term_emp.reload.status).to eq("terminated")
        expect(term_emp.current_profile.profile_status).to eq("terminated")
        expect(term_emp.emp_deltas.last.before).to eq({"status"=>"active", "end_date"=>nil, "profile_status"=>"active", "termination_date"=>nil})
        expect(term_emp.emp_deltas.last.after).to eq({"status"=>"terminated", "end_date"=>"2017-01-24 00:00:00 UTC", "profile_status"=>"terminated", "termination_date"=>"2017-01-24 00:00:00 UTC"})
        expect(term_emp.request_status).to eq("none")
      end

    end

    describe "leave event" do
      let!(:leave_emp) { FactoryGirl.create(:active_employee, leave_start_date: nil) }
      let!(:profile)   { FactoryGirl.create(:active_profile,
                         employee: leave_emp,
                         adp_employee_id: "100344") }
      let(:event)      { FactoryGirl.create(:adp_event,
                         kind: "worker.on-leave",
                         json: leave_json) }

      after :each do
        Timecop.return
      end

      it "should update leave date" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        Timecop.freeze(Time.new(2017, 1, 01, 5, 0, 0, "-07:00"))

        expect{
          adp.process_leave(event)
        }.to_not change{Employee.count}
        expect(leave_emp.reload.leave_start_date).to eq("2017-01-23")
        expect(leave_emp.emp_deltas.last.before).to eq({"leave_start_date"=>nil})
        expect(leave_emp.emp_deltas.last.after).to eq({"leave_start_date"=>"2017-01-23 00:00:00 UTC"})
      end

      it "should immediately put on leave if leave date is retroactive" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:deactivate)

        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_leave(event)
        }.to_not change{Employee.count}
        expect(leave_emp.reload.leave_start_date).to eq("2017-01-23")
        expect(leave_emp.emp_deltas.last.before).to eq({"status"=> "active", "profile_status"=>"active", "leave_start_date"=>nil,})
        expect(leave_emp.emp_deltas.last.after).to eq({"status"=> "inactive", "profile_status"=>"leave", "leave_start_date"=>"2017-01-23 00:00:00 UTC"})
      end
    end

    describe "leave event where employee not found" do
      let(:event)  { FactoryGirl.create(:adp_event,
                     kind: "worker.on-leave",
                     json: leave_json) }

      it "should save the event and return" do
        adp = AdpService::Events.new
        adp.token = "a-token-value"

        expect{
          adp.process_leave(event)
        }.to_not change{Employee.count}
      end
    end

    describe "rehire event" do
      let!(:worker_type)        { FactoryGirl.create(:worker_type, code: "FTR", kind: "Regular") }
      let!(:security_profile)   { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
      let!(:sec_access_service) { double(SecAccessService) }

      context "for worker without a mezzo record" do
        it "should not create a new employee record" do
          adp = AdpService::Events.new
          adp.token = "a-token-value"

          rehire_event = FactoryGirl.create(:adp_event,
            status: "New",
            json: rehire_json
          )

          expect{
            adp.process_rehire(rehire_event)
          }.not_to change{Employee.count}
        end

        it "should generate an onboarding form with the event" do
          adp = AdpService::Events.new
          adp.token = "a-token-value"

          rehire_event = FactoryGirl.create(:adp_event,
            status: "New",
            json: rehire_json
          )

          expect(EmployeeWorker).to receive(:perform_async)

          expect{
            adp.process_rehire(rehire_event)
          }.not_to change{Employee.count}
        end

      end

      context "for worker with a mezzo record" do
        term_date = Date.new(2017, 1, 1)
        let(:rehired_emp) { FactoryGirl.create(:terminated_employee,
                             hire_date: Date.new(2010, 9, 1),
                             termination_date: term_date) }
        let!(:profile)     { FactoryGirl.create(:terminated_profile,
                             start_date: Date.new(2010, 9, 1),
                             end_date: term_date,
                             employee: rehired_emp,
                             adp_employee_id: "123456") }
        let!(:sas)         { double(SecAccessService) }
        let(:manager)      { FactoryGirl.create(:active_employee) }
        let!(:man_prof)    { FactoryGirl.create(:active_profile,
                             adp_employee_id: "654321",
                             employee: manager) }

        it "finds and updates account with new position" do
          expect(SecAccessService).to receive(:new).and_return(sas)
          expect(sas).to receive(:apply_ad_permissions)
          expect(ActiveDirectoryService).to receive(:new).and_return(ads)
          expect(ads).to receive(:update)

          adp = AdpService::Events.new
          adp.token = "a-token-value"

          event = FactoryGirl.create(:adp_event,
            status: "New",
            json: rehire_json
          )
          expect{
            adp.process_rehire(event)
          }.to_not change{Employee.count}
          expect(rehired_emp.reload.status).to eq("pending")
          expect(rehired_emp.reload.termination_date).to eq(nil)
          expect(rehired_emp.reload.location.code).to eq("SF")
          expect(rehired_emp.reload.job_title.code).to eq("SPMASR")
          expect(rehired_emp.reload.hire_date).to eq(Date.new(2010, 9, 1))
          expect(rehired_emp.reload.termination_date).to eq(nil)
          expect(rehired_emp.profiles.count).to eq(3)
          expect(rehired_emp.current_profile.start_date).to eq(Date.new(2018, 9, 1))
          expect(rehired_emp.current_profile.profile_status).to eq("pending")
          expect(rehired_emp.profiles.terminated.last.start_date).to eq(Date.new(2010, 9, 1))
          expect(rehired_emp.profiles.terminated.last.end_date).to eq(term_date)
        end
      end

    end
  end
end
