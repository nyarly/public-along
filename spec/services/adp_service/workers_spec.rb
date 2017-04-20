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
  let(:pending_hire_contract_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_pending_contract_hire.json") }
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
    let!(:employee) { FactoryGirl.create(:employee, employee_id: "101455", job_title_id: 1, worker_type_id: 2, department_id: 3, location_id: 4)}
    let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_workers.json")) }
    let(:parser) { double(AdpService::WorkerJsonParser) }
    let(:sorted) {
      [{
        status: "Active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally Jesse",
        last_name: "Allansberg",
        employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        company: "OpenTable Inc.",
        job_title_id: 1,
        worker_type_id: 2,
        manager_id: "101734",
        department_id: 3,
        location_id: 4,
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411"
      }]
    }
    let(:emp_delta) { double(EmpDelta) }

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

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(EmpDelta).to receive(:new).and_return(emp_delta)
      expect(emp_delta).to receive(:save)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])

      allow(Employee).to receive(:check_manager)

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.first_name).to eq("Sally Jesse")
    end

    it "should make indicated manager if not already a manager" do
      manager_to_be = FactoryGirl.create(:employee, employee_id: "101734")
      sp = FactoryGirl.create(:security_profile, name: "Basic Manager")

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(EmpDelta).to receive(:new).and_return(emp_delta)
      expect(emp_delta).to receive(:save)
      expect(EmployeeWorker).not_to receive(:perform_async)
      expect(ActiveDirectoryService).to receive(:new).twice.and_return(ads)
      expect(ads).to receive(:update).with([employee])

      expect{
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      }.to change{Employee.managers.include?(manager_to_be)}.from(false).to(true)
    end

    it "should do nothing if manager already a manager" do
      manager = FactoryGirl.create(:employee, employee_id: "101734")
      sp = FactoryGirl.create(:security_profile, name: "Basic Manager")

      manager.security_profiles << sp

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(EmpDelta).to receive(:new).and_return(emp_delta)
      expect(emp_delta).to receive(:save)
      expect(EmployeeWorker).not_to receive(:perform_async)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])

      expect{
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      }.to_not change{Employee.managers.include?(manager)}
    end

    it "should send a security access form on department, worker type, location, or job title" do
      sorted = [{
        status: "Active",
        adp_assoc_oid: "G32B8JAXA1W398Z8",
        first_name: "Sally Jesse",
        last_name: "Allansberg",
        employee_id: "101455",
        hire_date: "2013-08-05",
        contract_end_date: nil,
        company: "OpenTable Inc.",
        job_title_id: 1,
        worker_type_id: 2,
        manager_id: "101734",
        department_id: 3,
        location_id: 777,
        office_phone: "(212) 555-4411",
        personal_mobile_phone: "(212) 555-4411"
      }]

      expect(response).to receive(:body).and_return(json)

      adp = AdpService::Workers.new
      adp.token = "a-token-value"

      expect(JSON).to receive(:parse).with(json)
      expect(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      expect(parser).to receive(:sort_workers).and_return(sorted)
      expect(EmpDelta).to receive(:new).and_return(emp_delta)
      expect(emp_delta).to receive(:save)
      expect(EmployeeWorker).to receive(:perform_async)
      expect(ActiveDirectoryService).to receive(:new).and_return(ads)
      expect(ads).to receive(:update).with([employee])

      adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(employee.reload.department_id).to eq(3)
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
    let!(:new_hire) {FactoryGirl.create(:employee,
      adp_assoc_oid: "G3NQ5754ETA080N",
      employee_id: "100015",
      status: "Pending",
      first_name: "Robert",
      hire_date: Date.today + 2.weeks
    )}
    let!(:future_date) { 1.year.from_now.change(:usec => 0) }
    let!(:regular_w_type) { FactoryGirl.create(:worker_type, code: "FTR")}

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

        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect{
          adp.check_new_hire_changes
        }.to_not change{Employee.count}

        new_hire.reload

        expect(new_hire.status).to eq("Pending")
        expect(new_hire.first_name).to eq("Bob")
        expect(new_hire.last_name).to eq("Seger")
        expect(new_hire.hire_date).to eq(DateTime.new(2018, 7, 12))
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

      it "should send an error message to TechTable if worker is not found" do
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
      check_contract_end_date = contract_end_date - 1

      let!(:new_hire) {FactoryGirl.create(:employee,
        adp_assoc_oid: "TESTOID",
        employee_id: "100015",
        status: "Pending",
        first_name: "Robert",
        contract_end_date: contract_end_date,
        hire_date: Date.today + 2.weeks
      )}

      before :each do
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/TESTOID?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pending_hire_contract_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        expect(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/TESTOID?asOfDate=#{check_contract_end_date.strftime('%m')}%2F#{check_contract_end_date.strftime('%d')}%2F#{check_contract_end_date.strftime('%Y')}").and_return(uri)
        expect(response).to receive(:body).and_return(pending_hire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
      end

      it "should should return blank" do
        adp = AdpService::Workers.new
        adp.token = "a-token-value"

        expect{
          adp.check_new_hire_changes
        }.to_not change{Employee.count}

        new_hire.reload
        expect(new_hire.status).to eq("Pending")
      end
    end
  end
end
