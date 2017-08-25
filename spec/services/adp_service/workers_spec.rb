require 'rails_helper'

describe AdpService::Workers, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:ads) { double(ActiveDirectoryService) }
  let(:pending_hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_pending_hire.json") }
  let(:contractor_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_contractor.json") }
  let(:terminated_contractor_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_terminated_contractor.json") }
  let(:not_found_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_worker_not_found.json") }

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
    let(:worker_type) { FactoryGirl.create(:worker_type)}
    let!(:employee) { FactoryGirl.create(:employee)}
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      adp_employee_id: "101455",
      adp_assoc_oid: "G32B8JAXA1W398Z8",
      worker_type: worker_type)}
    let(:json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json") }
    let(:parser) { double(AdpService::WorkerJsonParser) }
    let(:sorted) {
      [{
        status: "Active",
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
        department: FactoryGirl.create(:department),
        location: FactoryGirl.create(:location),
        worker_type: worker_type,
        job_title: FactoryGirl.create(:job_title),
        start_date: 2.weeks.ago,
        profile_status: "Active"
      }]
    }

    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should call parse json response, call #sort_workers and update employees" do
      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(Employee).to receive(:check_manager)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])
      expect(EmployeeWorker).to receive(:perform_async)
      allow(Employee).to receive(:check_manager)

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.first_name).to eq("Sally Jesse")
      expect(employee.reload.emp_deltas.count).to eq(1)
    end

    it "should make indicated manager if not already a manager" do
      manager_to_be = FactoryGirl.create(:employee)
      profile = FactoryGirl.create(:profile,
        employee: manager_to_be,
        adp_employee_id: "101734")
      sp = FactoryGirl.create(:security_profile, name: "Basic Manager")

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(ActiveDirectoryService).to receive(:new).twice.and_return(ads)
      expect(ads).to receive(:update).with([employee])

      expect{
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      }.to change{Employee.managers.include?(manager_to_be)}.from(false).to(true)
    end

    it "should do nothing if manager already a manager" do
      manager = FactoryGirl.create(:employee)
      m_prof = FactoryGirl.create(:profile,
        employee: manager,
        adp_employee_id: "100449")
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
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])

      expect{
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      }.to_not change{Employee.managers.include?(manager)}
    end

    it "should send a security access form on department, worker type, location, or job title" do
      new_department = FactoryGirl.create(:department)
      sorted = [{
        status: "Active",
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
        department: new_department,
        location: FactoryGirl.create(:location),
        worker_type: worker_type,
        job_title: FactoryGirl.create(:job_title),
        start_date: Date.today,
        profile_status: "Active"
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
        status: "Active",
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
        department: FactoryGirl.create(:department),
        location: FactoryGirl.create(:location),
        worker_type: FactoryGirl.create(:worker_type),
        job_title: new_job_title,
        start_date: Date.today,
        profile_status: "Active"
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
  end

  describe "check leave return" do
    let!(:leave_emp) {FactoryGirl.create(:employee,
      status: "Inactive",
      leave_return_date: nil,
      updated_at: 1.day.ago) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: leave_emp,
      profile_status: "Active",
      adp_assoc_oid: "123456") }
    let!(:leave_cancel_emp) {FactoryGirl.create(:employee,
      status: "Inactive",
      leave_return_date: Date.today + 2.days,
      updated_at: 1.day.ago) }
    let!(:lce_profile) {FactoryGirl.create(:profile,
      employee: leave_cancel_emp,
      profile_status: "Active",
      adp_assoc_oid: "123457") }
    let!(:do_nothing_emp) {FactoryGirl.create(:employee,
      status: "Inactive",
      leave_return_date: nil,
      updated_at: 1.day.ago) }
    let!(:dn_profile) { FactoryGirl.create(:profile,
      employee: do_nothing_emp,
      profile_status: "Active",
      adp_assoc_oid: "123458")}
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

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect{
        adp.check_leave_return
      }.to_not change{Employee.count}
      expect(leave_emp.reload.leave_return_date).to eq(future_date)
      expect(leave_cancel_emp.reload.leave_return_date).to eq(nil)
      expect(do_nothing_emp.reload.leave_return_date).to eq(nil)
    end
  end

  describe "check new hire changes" do
    let!(:regular_w_type) { FactoryGirl.create(:worker_type, code: "FTR")}
    let!(:new_hire) {FactoryGirl.create(:employee,
      first_name: "Robert",
      hire_date: Date.new(2017, 7, 12),
      status: "Pending") }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: new_hire,
      start_date: Date.new(2017, 7, 12),
      profile_status: "Pending",
      adp_assoc_oid: "G3NQ5754ETA080N",
      adp_employee_id: "100015",
      worker_type: regular_w_type
    )}
    let!(:future_date) { 1.year.from_now.change(:usec => 0) }

    context "worker found" do
      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pending_hire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
      end

      it "should update worker information and call AD update if info changed" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update).with([new_hire])
        expect(EmployeeWorker).not_to receive(:perform_async)

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect{
          adp.check_new_hire_changes
        }.to_not change{Employee.count}

        new_hire.reload

        emp_delta = EmpDelta.where(employee_id: new_hire.id).last

        expect(new_hire.status).to eq("Pending")
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
      end

      xit "should send an error message to TechTable if worker is not found" do
        expect(ActiveDirectoryService).to_not receive(:new)

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect(TechTableMailer).to receive(:alert_email)
          .with("New hire sync is erroring on #{new_hire.cn}, employee id: #{new_hire.employee_id}.\nPlease contact the developer to help diagnose the problem.")
          .and_return(mailer)
        expect(mailer).to receive(:deliver_now)

        adp.check_new_hire_changes
      end
    end

    context "worker has contract end date less than one year" do
      contract_end_date = Date.today + 3.months
      check_contract_end_date = contract_end_date - 1.day
      let!(:worker_type) {FactoryGirl.create(:worker_type,
        code: "ACW",
        kind: "Contractor")}
      let!(:new_hire) {FactoryGirl.create(:employee,
        status: "Pending",
        first_name: "Robert",
        contract_end_date: contract_end_date,
        hire_date: Date.today + 2.weeks)}
      let!(:profile) { FactoryGirl.create(:profile,
        profile_status: "Pending",
        employee: new_hire,
        adp_employee_id: "100015",
        adp_assoc_oid: "G3NQ5754ETA080N",
        worker_type: worker_type)}

      before :each do
        # return worker json with status "Terminated" on first try
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(terminated_contractor_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        # return worker json with status "Active" on second try
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{check_contract_end_date.strftime('%m')}%2F#{check_contract_end_date.strftime('%d')}%2F#{check_contract_end_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(contractor_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
      end

      it "should should update data for worker" do
        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect{
          adp.check_new_hire_changes
        }.to_not change{Employee.count}

        new_hire.reload
        expect(new_hire.first_name).to eq("Bob")
        expect(new_hire.last_name).to eq("Seger")
        expect(new_hire.status).to eq("Pending")
        expect(new_hire.profiles.count).to eq(1)
        expect(new_hire.current_profile.profile_status).to eq("Pending")
      end
    end

    context "new hire's manager is new manager" do

      check_date = 1.year.from_now.change(:usec => 0)

      let!(:new_manager) { FactoryGirl.create(:employee)}
      let!(:manager_prof) { FactoryGirl.create(:profile,
        employee: new_manager,
        profile_status: "Active",
        adp_employee_id: "100345") }
      let!(:basic_manager_sec_prof) { FactoryGirl.create(:security_profile,
        name: "Basic Manager") }
      let!(:new_hire) { FactoryGirl.create(:employee,
        status: "Pending",
        hire_date: Date.today + 4.days)}
      let!(:profile) { FactoryGirl.create(:profile,
        employee: new_hire,
        profile_status: "Pending",
        adp_employee_id: "123456",
        adp_assoc_oid: "TESTOID",
        manager_id: "100345")}

      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/TESTOID?asOfDate=#{check_date.strftime('%m')}%2F#{check_date.strftime('%d')}%2F#{check_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pending_hire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
      end

      it "should update the new hire's manager with the correct security profile" do
        adp = AdpService::Workers.new
        adp.token = "a-token-value"
        adp.check_new_hire_changes

        expect(new_hire.manager_id).to eq(new_manager.employee_id)
        expect(new_manager.active_security_profiles).to include(basic_manager_sec_prof)
      end
    end
  end
end
