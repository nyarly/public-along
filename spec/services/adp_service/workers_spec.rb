require 'rails_helper'

describe AdpService::Workers, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:ads)         { double(ActiveDirectoryService) }
  let(:pending_hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_pending_hire.json") }
  let(:pend_rehire_json)  { File.read(Rails.root.to_s+"/spec/fixtures/adp_pending_rehire.json") }
  let(:contractor_json)   { File.read(Rails.root.to_s+"/spec/fixtures/adp_contractor.json") }
  let(:not_found_json)    { File.read(Rails.root.to_s+"/spec/fixtures/adp_worker_not_found.json") }

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
    expect(AdpService::Workers.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
  end

  describe "worker_count" do
    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers?$select=workers/workerStatus&$top=1&count=true").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
        expect(response).to receive(:code)
        expect(response).to receive(:message)
    end

    it "should find a worker count" do
      expect(response).to receive(:body).and_return('{"meta":{"totalNumber": 1800}}')

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp.worker_count).to eq(1800)
    end
  end

  describe "create_worker_urls" do
    it "should create URL pages to call based on count" do

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp).to receive(:worker_count).and_return(375)

      expect(adp.create_worker_urls).to eq([
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=0",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=25",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=50",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=75",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=100",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=125",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=150",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=175",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=200",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=225",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=250",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=275",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=300",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=325",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=350",
       "https://api.adp.com/hr/v2/workers?$top=25&$skip=375"
      ])
    end
  end

  describe "create_sidekiq_workers" do
    it "should call sidekiq workers" do
      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(adp).to receive(:worker_count).and_return(175)

      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=0")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=50")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=75")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=100")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=125")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=150")
      expect(AdpWorker).to receive(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=175")

      adp.create_sidekiq_workers
    end
  end

  describe "sync_workers" do
    let(:worker_type) { FactoryGirl.create(:worker_type) }
    let(:manager) { FactoryGirl.create(:active_employee)}
    let!(:manager_profile)    { FactoryGirl.create(:active_profile,
                        employee: manager,
                        adp_employee_id: "101734",
                        management_position: true) }
    let(:employee)    { FactoryGirl.create(:active_employee,
                        first_name: "BOB") }
    let!(:profile)    { FactoryGirl.create(:active_profile,
                        employee: employee,
                        adp_employee_id: "101455",
                        adp_assoc_oid: "G32B8JAXA1W398Z8",
                        worker_type: worker_type) }
    let(:json)        { File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json") }
    let(:parser)      { double(AdpService::WorkerJsonParser) }
    let(:sas)         { double(SecAccessService) }

    let(:sorted) {
      [{
        status: "active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally Jesse",
        last_name: "Allansberg",
        adp_employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        company: "OpenTable Inc.",
        manager_adp_employee_id: "101734",
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411",
        department_id: FactoryGirl.create(:department).id,
        location_id: FactoryGirl.create(:location).id,
        worker_type_id: worker_type.id,
        job_title_id: FactoryGirl.create(:job_title).id,
        start_date: 2.weeks.ago,
        profile_status: "active",
        manager_id: manager.id
      }]
    }

    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
      expect(response).to receive(:code)
      expect(response).to receive(:message)
    end

    it "should call parse json response, call #sort_workers and update employees" do
      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])
      expect(EmployeeWorker).to receive(:perform_async)
      expect(EmployeeService::GrantManagerAccess).to receive_message_chain(:new, :process!)

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.first_name).to eq("Sally Jesse")
      expect(employee.reload.emp_deltas.count).to eq(1)
    end

    it "should make indicated manager if not already a manager" do
      sp = FactoryGirl.create(:security_profile, name: "Basic Manager")
      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(ActiveDirectoryService).to receive(:new).twice.and_return(ads)
      expect(ads).to receive(:update).with([employee])
      expect(ads).to receive(:scan_for_failed_ldap_transactions)

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.manager.emp_transactions.last.kind).to eq("Service")
      expect(employee.reload.manager.emp_transactions.last.emp_sec_profiles.last.security_profile_id).to eq(sp.id)
    end

    it "should do nothing if manager already a manager" do
      manager = FactoryGirl.create(:active_employee)
      m_prof = FactoryGirl.create(:active_profile,
        employee: manager,
        adp_employee_id: "100449",
        management_position: true)
      sp = FactoryGirl.create(:security_profile, name: "Basic Manager")
      emp_transaction = FactoryGirl.create(:emp_transaction,
        employee_id: manager.id)
      FactoryGirl.create(:emp_sec_profile,
        security_profile_id: sp.id,
        emp_transaction_id: emp_transaction.id)

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(ActiveDirectoryService).to receive(:new).twice.and_return(ads)
      expect(ads).to receive(:update).with([employee])
      expect(ads).to receive(:scan_for_failed_ldap_transactions)

      expect{
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      }.to_not change{manager.security_profiles}
    end

    it "should send a security access form on department, worker type, location, or job title" do
      new_department = FactoryGirl.create(:department)
      sorted = [{
        status: "active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally Jesse",
        last_name: "Allansberg",
        adp_employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        company: "OpenTable Inc.",
        manager_id: "101734",
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411",
        department_id: new_department.id,
        location_id: FactoryGirl.create(:location).id,
        worker_type_id: worker_type.id,
        job_title_id: FactoryGirl.create(:job_title).id,
        start_date: Date.today,
        profile_status: "active"
      }]

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(EmployeeWorker).to receive(:perform_async)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.department).to eq(new_department)
    end

    it "should not send an email if it did recently" do
      new_job_title = FactoryGirl.create(:job_title)
      sorted = [{
        status: "active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally Jesse",
        last_name: "Allansberg",
        adp_employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        company: "OpenTable Inc.",
        manager_id: "101734",
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411",
        department_id: FactoryGirl.create(:department).id,
        location_id: FactoryGirl.create(:location).id,
        worker_type_id: FactoryGirl.create(:worker_type).id,
        job_title_id: new_job_title.id,
        start_date: Date.today,
        profile_status: "active"
      }]

      previous_change = FactoryGirl.create(:emp_delta,
        employee_id: employee.id,
        before: {"location_id" => 1},
        after: {"location_id" => 2},
        created_at: 1.hour.ago )

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])
      expect(EmployeeWorker).not_to receive(:perform_async)

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.job_title.id).to eq(new_job_title.id)
    end

    context "contractor termination" do
      let(:contractor)  { FactoryGirl.create(:employee,
                          last_name: "blah",
                          status: "terminated",
                          contract_end_date: Date.today,
                          termination_date: nil) }
      let!(:profile)    { FactoryGirl.create(:profile,
                          profile_status: "terminated",
                          employee: contractor,
                          adp_employee_id: "101455")}
      let(:sorted)      {[{
                          adp_employee_id: "101455",
                          status: "active",
                          profile_status: "active"
                        }]}

      it "should not reactivate after mezzo termiantion" do
        expect(response).to receive(:body).and_return(json)

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect(JSON).to receive(:parse).with(json)
        expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
        expect(parser).to receive(:sort_workers).and_return(sorted)
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")

        expect(contractor.reload.status).to eq("terminated")
      end
    end

    context "contractor to full-time conversion" do
      let(:last_day)    { 6.days.from_now }
      let(:contractor)  { FactoryGirl.create(:employee,
                          status: "active",
                          contract_end_date: nil,
                          termination_date: nil) }
      let!(:profile)    { FactoryGirl.create(:profile,
                          profile_status: "active",
                          employee: contractor,
                          start_date: 1.year.ago,
                          end_date: last_day,
                          adp_employee_id: "101455") }
      let!(:new_prof)   { FactoryGirl.create(:profile,
                          profile_status: "pending",
                          employee: contractor,
                          start_date: last_day,
                          adp_employee_id: "newid123") }
      let(:sorted)      {[{
                          adp_employee_id: "101455",
                          status: "active",
                          profile_status: "active",
                          contract_end_date: 6.days.from_now
                        }]}

      it "should only sync changes to current profile" do
        expect(response).to receive(:body).and_return(json)

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect(JSON).to receive(:parse).with(json)
        expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
        expect(parser).to receive(:sort_workers).and_return(sorted)
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")

        contractor.reload

        expect(contractor.status).to eq("active")
        expect(contractor.profiles.count).to eq(2)
        expect(contractor.profiles.pending).to eq([new_prof])
        expect(contractor.contract_end_date).to eq(nil)
        expect(contractor.current_profile.end_date).to eq(last_day)
        expect(contractor.termination_date).to eq(nil)
        expect(contractor.emp_deltas.count).to eq(0)
      end
    end
  end

  describe "check leave return" do
    let!(:leave_emp) {FactoryGirl.create(:leave_employee,
      leave_return_date: nil,
      updated_at: 1.day.ago) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: leave_emp,
      profile_status: "leave",
      adp_assoc_oid: "123456") }
    let!(:leave_cancel_emp) {FactoryGirl.create(:leave_employee,
      leave_return_date: Date.today + 2.days,
      updated_at: 1.day.ago) }
    let!(:lce_profile) {FactoryGirl.create(:profile,
      employee: leave_cancel_emp,
      profile_status: "leave",
      adp_assoc_oid: "123457") }
    let!(:do_nothing_emp) {FactoryGirl.create(:leave_employee,
      leave_return_date: nil,
      updated_at: 1.day.ago) }
    let!(:dn_profile) { FactoryGirl.create(:profile,
      employee: do_nothing_emp,
      profile_status: "leave",
      adp_assoc_oid: "123458")}
    let!(:future_date) { 1.day.from_now.change(:usec => 0) }


    it "should create the right employee workers" do
      expect(EmployeeChangeWorker).to receive(:perform_async).with(leave_emp.id)
      expect(EmployeeChangeWorker).to receive(:perform_async).with(leave_cancel_emp.id)
      expect(EmployeeChangeWorker).to receive(:perform_async).with(do_nothing_emp.id)
      adp = AdpService::Workers.new
      adp.token = "a-token-value"
      expect{
        adp.check_future_changes
      }.to_not change{Employee.count}
    end

    it "should update leave return date and call AD update when it gets an active response" do
      adp = AdpService::Workers.new
      adp.token = "a-token-value"
      expect(URI).to receive(:parse).ordered.with("https://api.adp.com/hr/v2/workers/123456?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
      expect(http).to receive(:get).and_return(response)
      expect(response).to receive(:body).and_return(
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
      expect(response).to receive(:code)
      expect(response).to receive(:message)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([leave_emp])

      adp.check_leave_return(leave_emp)

      expect(leave_emp.reload.leave_return_date).to eq(future_date)
      expect(leave_emp.emp_deltas.last.before).to eq({"leave_return_date"=>nil})
      expect(leave_emp.emp_deltas.last.after).to eq({"leave_return_date"=>"#{future_date.change(:usec => 0)}"})
    end

    it "should update leave return date to nil and call AD when it gets an inactive response" do
      adp = AdpService::Workers.new
      adp.token = "a-token-value"
      expect(URI).to receive(:parse).ordered.with("https://api.adp.com/hr/v2/workers/123457?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
      expect(http).to receive(:get).and_return(response)
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
      expect(response).to receive(:code)
      expect(response).to receive(:message)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([leave_cancel_emp])

      adp.check_leave_return(leave_cancel_emp)

      expect(leave_cancel_emp.reload.leave_return_date).to eq(nil)
      expect(leave_cancel_emp.emp_deltas.last.after).to eq({"leave_return_date"=>nil})
    end

    it "should do nothing when the worker is still on leave" do
      adp = AdpService::Workers.new
      adp.token = "a-token-value"
      expect(URI).to receive(:parse).ordered.with("https://api.adp.com/hr/v2/workers/123458?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
      expect(http).to receive(:get).and_return(response)
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
      expect(response).to receive(:code)
      expect(response).to receive(:message)
      expect(ActiveDirectoryService).not_to receive(:new)

      adp.check_leave_return(do_nothing_emp)

      expect(do_nothing_emp.reload.leave_return_date).to eq(nil)
    end
  end

  describe "check new hire changes" do
    let!(:regular_w_type) { FactoryGirl.create(:worker_type, code: "FTR")}
    let!(:new_hire) {FactoryGirl.create(:pending_employee,
      first_name: "Robert",
      hire_date: Date.new(2017, 7, 12)) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: new_hire,
      start_date: Date.new(2017, 7, 12),
      profile_status: "pending",
      adp_assoc_oid: "G3NQ5754ETA080N",
      adp_employee_id: "100015",
      worker_type: regular_w_type) }
    let!(:future_date) { 1.year.from_now.change(:usec => 0) }

    it "should create the right employee workers" do
      expect(EmployeeChangeWorker).to receive(:perform_async).with(new_hire.id)
      adp = AdpService::Workers.new
      adp.token = "a-token-value"
      expect{
        adp.check_future_changes
      }.to_not change{Employee.count}
    end

    context "worker found" do
      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pending_hire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        expect(response).to receive(:code)
        expect(response).to receive(:message)
      end

      it "should update worker information and call AD update if info changed" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update).with([new_hire])
        expect(EmployeeWorker).not_to receive(:perform_async)

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect{
          adp.check_new_hire_change(new_hire)
        }.to_not change{Employee.count}

        new_hire.reload

        emp_delta = EmpDelta.where(employee_id: new_hire.id).last

        expect(new_hire.status).to eq("pending")
        expect(new_hire.first_name).to eq("Bob")
        expect(new_hire.last_name).to eq("Seger")
        expect(new_hire.hire_date).to eq(DateTime.new(2018, 7, 12))
        expect(emp_delta.before['first_name']).to eq("Robert")
        expect(emp_delta.after['first_name']).to eq("Bob")
      end
    end

    context "worker not found" do
      let(:mailer) { double(TechTableMailer) }

      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(not_found_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        expect(response).to receive(:code)
        expect(response).to receive(:message)
      end

      it "should send an error message to TechTable if worker is not found" do
        expect(ActiveDirectoryService).to_not receive(:new)

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect(TechTableMailer).to receive(:alert_email)
          .with("Cannot get updated ADP info for new contract hire #{new_hire.cn}, employee id: #{new_hire.employee_id}.\nPlease contact the developer to help diagnose the problem.")
          .and_return(mailer)
        expect(mailer).to receive(:deliver_now)

        adp.check_new_hire_change(new_hire)
      end
    end

    context "worker has contract end date less than one year" do
      contract_end_date = Date.today + 3.months
      check_contract_end_date = contract_end_date - 1.day
      let!(:worker_type) { FactoryGirl.create(:worker_type,
        code: "ACW",
        kind: "Contractor")}
      let!(:new_hire) { FactoryGirl.create(:employee,
        status: "pending",
        first_name: "Robert",
        contract_end_date: contract_end_date,
        hire_date: Date.today + 2.weeks)}
      let!(:profile) { FactoryGirl.create(:profile,
        profile_status: "pending",
        employee: new_hire,
        adp_employee_id: "100015",
        adp_assoc_oid: "G3NQ5754ETA080N",
        worker_type: worker_type)}

      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{check_contract_end_date.strftime('%m')}%2F#{check_contract_end_date.strftime('%d')}%2F#{check_contract_end_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(contractor_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        expect(response).to receive(:code)
        expect(response).to receive(:message)
      end

      it "should should update data for worker" do
        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect{
          adp.check_new_hire_change(new_hire)
        }.to_not change{Employee.count}

        new_hire.reload
        expect(new_hire.first_name).to eq("Bob")
        expect(new_hire.last_name).to eq("Seger")
        expect(new_hire.status).to eq("pending")
        expect(new_hire.profiles.count).to eq(1)
        expect(new_hire.current_profile.profile_status).to eq("pending")
      end
    end

    context "new hire's manager is new manager" do
      check_date = 1.year.from_now.change(:usec => 0)

      let!(:new_manager) { FactoryGirl.create(:active_employee) }
      let!(:manager_prof) { FactoryGirl.create(:active_profile,
        employee: new_manager,
        adp_employee_id: "100345",
        management_position: true) }
      let!(:basic_manager_sec_prof) { FactoryGirl.create(:security_profile,
        name: "Basic Manager") }
      let!(:new_hire) { FactoryGirl.create(:employee,
        status: "pending",
        hire_date: Date.today + 4.days)}
      let!(:profile) { FactoryGirl.create(:profile,
        employee: new_hire,
        profile_status: "pending",
        adp_employee_id: "123456",
        adp_assoc_oid: "TESTOID") }

      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/TESTOID?asOfDate=#{check_date.strftime('%m')}%2F#{check_date.strftime('%d')}%2F#{check_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pending_hire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        expect(response).to receive(:code)
        expect(response).to receive(:message)
      end

      it "should update the new hire's manager with the correct security profile" do
        adp = AdpService::Workers.new
        adp.token = "a-token-value"
        adp.check_new_hire_change(new_hire)

        expect(new_hire.manager_id).to eq(new_manager.id)
        expect(new_manager.active_security_profiles).to include(basic_manager_sec_prof)
      end
    end

    context "rehire changes" do
      let!(:ptt_wt)      { FactoryGirl.create(:worker_type, code: "PTT") }
      let!(:jt)          { FactoryGirl.create(:job_title, code: "BRDSRNE") }
      let!(:dept)        { FactoryGirl.create(:department, code: "063050") }
      let!(:rehire)      { FactoryGirl.create(:employee,
                           status: "pending",
                           hire_date: Date.new(2016, 10, 26)) }
      let!(:old_profile) { FactoryGirl.create(:terminated_profile,
                           employee: rehire,
                           start_date: Date.new(2016, 10, 26),
                           end_date: Date.new(2016, 12, 9),
                           adp_assoc_oid: "G3NGJ6TFKN7ZWHBP",
                           adp_employee_id: "102058",
                           worker_type: ptt_wt) }
      let!(:new_profile) { FactoryGirl.create(:profile,
                           employee: rehire,
                           start_date: Date.new(2017, 11, 1),
                           adp_assoc_oid: "G3NGJ6TFKN7ZWHBP",
                           adp_employee_id: "102058",
                           worker_type: ptt_wt) }

      before :each do
        check_date = 1.year.from_now.change(:usec => 0)
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NGJ6TFKN7ZWHBP?asOfDate=#{check_date.strftime('%m')}%2F#{check_date.strftime('%d')}%2F#{check_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pend_rehire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        expect(response).to receive(:code)
        expect(response).to receive(:message)
      end

      it "should get the correct profile" do
        adp = AdpService::Workers.new
        adp.token = "a-token-value"
        adp.check_new_hire_change(rehire)

        expect(rehire.profiles.count).to eq(2)
        expect(rehire.hire_date).to eq(Date.new(2016, 10, 26))
        expect(rehire.termination_date).to eq(nil)
        expect(rehire.contract_end_date).to eq(nil)
        expect(rehire.profiles.terminated.reorder(:created_at).last.start_date).to eq(Date.new(2016, 10, 26))
        expect(rehire.profiles.terminated.reorder(:created_at).last.end_date).to eq(Date.new(2016, 12, 9))
        expect(rehire.profiles.pending.reorder(:created_at).last.start_date).to eq(Date.new(2017, 10, 16))
        expect(rehire.profiles.pending.reorder(:created_at).last.end_date).to eq(nil)
      end
    end
  end
end
