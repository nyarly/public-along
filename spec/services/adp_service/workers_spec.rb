require 'rails_helper'

describe AdpService::Workers, type: :service do
  let(:adp)         { AdpService::Workers.new }
  let(:url)         { 'https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials' }
  let(:uri)         { double(URI) }
  let(:host)        { 'accounts.adp.com' }
  let(:port)        { 443 }
  let(:request_uri) { '/auth/oauth/v2/token?grant_type=client_credentials' }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:ads)         { double(ActiveDirectoryService) }
  let(:pending_hire_json) { File.read(Rails.root.to_s + '/spec/fixtures/adp_pending_hire.json') }
  let(:pend_rehire_json)  { File.read(Rails.root.to_s + '/spec/fixtures/adp_pending_rehire.json') }
  let(:contractor_json)   { File.read(Rails.root.to_s + '/spec/fixtures/adp_contractor.json') }
  let(:not_found_json)    { File.read(Rails.root.to_s + '/spec/fixtures/adp_worker_not_found.json') }

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
      { 'Accept' => 'application/json',
        'Authorization' => "Basic #{SECRETS.adp_creds}",
      }).and_return(response)
    allow(response).to receive(:body).and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  describe 'retrieving token' do
    it 'should get a bearer token from ADP' do
      expect(AdpService::Workers.new.token).to eq('7890f85c-43ef-4ebc-acb7-f98f2c0581d0')
    end
  end

  describe '#worker_count' do
    before do
      adp.token = 'a-token-value'
      allow(URI).to receive(:parse).with('https://api.adp.com/hr/v2/workers?$select=workers/workerStatus&$top=1&count=true').and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { 'Accept'=>'application/json',
          'Authorization'=>'Bearer a-token-value',
        }).and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
      allow(response).to receive(:body).and_return('{"meta":{"totalNumber": 1800}}')
    end

    it 'should find a worker count' do
      expect(adp.worker_count).to eq(1800)
    end
  end

  describe '#create_worker_urls' do
    before do
      allow(adp).to receive(:worker_count).and_return(375)
    end

    it 'should create URL pages to call based on count' do
      expect(adp.create_worker_urls).to eq([
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=0',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=25',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=50',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=75',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=100',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=125',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=150',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=175',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=200',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=225',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=250',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=275',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=300',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=325',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=350',
       'https://api.adp.com/hr/v2/workers?$top=25&$skip=375'
      ])
    end
  end

  describe '#create_sidekiq_workers' do
    before do
      allow(adp).to receive(:worker_count).and_return(175)
      allow(AdpWorker).to receive(:perform_async)

      adp.create_sidekiq_workers
    end

    it 'should call sidekiq workers' do
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=0")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=50")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=75")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=100")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=125")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=150")
      expect(AdpWorker).to have_received(:perform_async).with("https://api.adp.com/hr/v2/workers?$top=25&$skip=175")
    end
  end

  describe '#sync_workers' do
    let(:json)        { File.read(Rails.root.to_s + '/spec/fixtures/adp_workers.json') }
    let(:adp)         { AdpService::Workers.new }
    let(:sas)         { double(SecAccessService) }
    let(:parser)      { double(AdpService::WorkerJsonParser) }
    let(:worker_type) { FactoryGirl.create(:worker_type) }
    let(:manager)     { FactoryGirl.create(:active_employee)}
    let(:employee)    { FactoryGirl.create(:employee, status: 'active', first_name: 'BOB') }

    let(:sorted) do
      [{
        adp_status: 'active',
        adp_assoc_oid: 'G32B8JAXA1W398Z8',
        first_name: 'Sally Jesse',
        last_name: 'Allansberg',
        adp_employee_id: '101455',
        hire_date: '2013-08-05',
        contract_end_date: nil,
        company: 'OpenTable Inc.',
        manager_adp_employee_id: '101734',
        office_phone: '(212) 555-4411',
        personal_mobile_phone: '(212) 555-4411',
        department_id: FactoryGirl.create(:department).id,
        location_id: FactoryGirl.create(:location).id,
        worker_type_id: worker_type.id,
        job_title_id: FactoryGirl.create(:job_title).id,
        start_date: 2.weeks.ago,
        profile_status: 'active',
        manager_id: manager.id
      }]
    end

    before do
      FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: manager,
        adp_employee_id: '101734',
        management_position: true)

      adp.token = 'a-token-value'
      allow(URI).to receive(:parse).with('https://api.adp.com/hr/v2/workers?$top=25&$skip=25').and_return(uri)
      allow(http).to receive(:get).with(
        request_uri,
        { 'Accept' => 'application/json',
          'Authorization' => 'Bearer a-token-value',
        }).and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)
      allow(response).to receive(:body).and_return(json)
      allow(AdpService::WorkerJsonParser).to receive(:new).and_return(parser)
      allow(EmployeeWorker).to receive(:perform_async)
      allow(ActiveDirectoryService).to receive(:new).and_return(ads)
      allow(ads).to receive(:update)
      allow(ads).to receive(:scan_for_failed_ldap_transactions)
    end

    context 'when worker info changes' do
      before do
        FactoryGirl.create(:profile,
          profile_status: 'active',
          employee: employee,
          adp_employee_id: '101455',
          adp_assoc_oid: 'G32B8JAXA1W398Z8',
          worker_type: worker_type)

        allow(parser).to receive(:sort_workers).and_return(sorted)
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
        employee.reload
      end

      it 'updates AD' do
        expect(ads).to have_received(:update).with([employee])
      end

      it 'updates the worker name' do
        expect(employee.first_name).to eq("Sally Jesse")
      end

      it 'creates an emp delta with the change' do
        expect(employee.emp_deltas.count).to eq(1)
      end

      it 'does not change status' do
        expect(employee.status).to eq('active')
        expect(employee.adp_status).to eq('active')
      end

      it 'processes the change' do
        expect(EmployeeWorker).to have_received(:perform_async)
      end
    end

    context 'when worker has a change that should send security access form' do
      let(:new_department) { FactoryGirl.create(:department) }
      let(:sorted) do
        [{
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
      end

      before do
        FactoryGirl.create(:profile,
          profile_status: 'active',
          employee: employee,
          adp_employee_id: '101455',
          adp_assoc_oid: 'G32B8JAXA1W398Z8',
          worker_type: worker_type)

        allow(parser).to receive(:sort_workers).and_return(sorted)
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      end

      it 'assigns the new department' do
        expect(employee.reload.department).to eq(new_department)
      end

      it 'processes the transaction' do
        expect(EmployeeWorker).to have_received(:perform_async)
      end

      it 'updates AD' do
        expect(ads).to have_received(:update).with([employee])
      end
    end

    context 'when manager recently got a security access form email' do
      let(:worker_type) { FactoryGirl.create(:worker_type) }
      let(:new_job_title) { FactoryGirl.create(:job_title) }
      let(:sorted) do
        [{
          status: 'active',
          adp_assoc_oid: 'G32B8JAXA1W398Z8',
          first_name: 'Sally Jesse',
          last_name: 'Allansberg',
          adp_employee_id: '101455',
          hire_date: '2013-08-05',
          contract_end_date: nil,
          company: 'OpenTable Inc.',
          manager_id: '101734',
          office_phone: '(212) 555-4411',
          personal_mobile_phone: '(212) 555-4411',
          department_id: FactoryGirl.create(:department).id,
          location_id: FactoryGirl.create(:location).id,
          worker_type_id: worker_type.id,
          job_title_id: new_job_title.id,
          start_date: Date.today,
          profile_status: 'active'
        }]
      end

      before do
        FactoryGirl.create(:profile,
          profile_status: 'active',
          employee: employee,
          adp_employee_id: '101455',
          adp_assoc_oid: 'G32B8JAXA1W398Z8',
          worker_type: worker_type)

        FactoryGirl.create(:emp_delta,
          employee_id: employee.id,
          before: { 'location_id' => 1 },
          after: { 'location_id' => 2 },
          created_at: 1.hour.ago )

        allow(parser).to receive(:sort_workers).and_return(sorted)
        adp.sync_workers("https://api.adp.com/hr/v2/workers?$top=25&$skip=25")
      end

      it 'assigns the change' do
        expect(employee.reload.job_title.id).to eq(new_job_title.id)
      end

      it 'does not email the manager' do
        expect(EmployeeWorker).not_to have_received(:perform_async)
      end
    end

    context 'with offboarded contractor' do
      let!(:contractor) do
        FactoryGirl.create(:employee,
          status: 'terminated',
          adp_status: 'active',
          contract_end_date: Date.today,
          termination_date: nil)
      end

      let(:sorted) do
        [{
          adp_employee_id: '101455',
          adp_status: 'active',
          profile_status: 'active'
        }]
      end

      before do
        FactoryGirl.create(:profile,
          profile_status: 'terminated',
          employee: contractor,
          adp_employee_id: '101455')
        allow(parser).to receive(:sort_workers).and_return(sorted)
        adp.sync_workers('https://api.adp.com/hr/v2/workers?$top=25&$skip=25')
      end

      it 'checks for updates' do
        expect(ads).to have_received(:update).with([contractor])
      end

      it 'has the correct mezzo status' do
        expect(contractor.reload.status).to eq('terminated')
      end

      it 'has the correct adp status' do
        expect(contractor.reload.adp_status).to eq('active')
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

  describe '#look_ahead' do
    let(:adp) { AdpService::Workers.new }

    before do
      check_date = 1.year.from_now.change(usec: 0)
      allow(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NGJ6TFKN7ZWHBP?asOfDate=#{check_date.strftime('%m')}%2F#{check_date.strftime('%d')}%2F#{check_date.strftime('%Y')}").and_return(uri)
      allow(response).to receive(:body).and_return(pend_rehire_json)
      allow(http).to receive(:get).with(
        request_uri,
        { 'Accept' => 'application/json',
          'Authorization' => 'Bearer a-token-value',
        }).and_return(response)
      allow(response).to receive(:code)
      allow(response).to receive(:message)

      allow(adp).to receive(:check_new_hire_change)
      allow(adp).to receive(:check_leave_return)
    end

    context 'when worker is pending' do
      let(:new_hire) do
        FactoryGirl.create(:employee,
          status: 'pending',
          hire_date: Date.today + 4.days)
      end

      before do
        FactoryGirl.create(:profile,
          employee: new_hire,
          profile_status: 'pending',
          adp_employee_id: '123456',
          adp_assoc_oid: 'TESTOID')
        adp.look_ahead(new_hire)
      end

      it 'checks for new hire changes' do
        expect(adp).to have_received(:check_new_hire_change).with(new_hire)
      end
    end

    context 'when worker is on leave' do
      let(:leave_emp) { FactoryGirl.create(:employee, status: 'inactive') }

      before do
        FactoryGirl.create(:profile,
          employee: leave_emp,
          profile_status: 'leave',
          adp_employee_id: '123456',
          adp_assoc_oid: 'TESTOID')
      end

      it 'checks for leave return date' do
        adp.look_ahead(leave_emp)
        expect(adp).to have_received(:check_leave_return).with(leave_emp)
      end
    end

    context 'when worker account has been activated' do
      let(:worker) { FactoryGirl.create(:employee, status: 'active',
          hire_date: Date.today + 4.days) }

      before do
        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'leave',
          adp_employee_id: '123456',
          adp_assoc_oid: 'TESTOID')
      end

      it 'does nothing' do
        adp.look_ahead(worker)
        expect(adp).not_to have_received(:check_leave_return).with(worker)
        expect(adp).not_to have_received(:check_new_hire_change).with(worker)
      end
    end
  end

  describe "check leave return" do
    let!(:leave_emp) {FactoryGirl.create(:employee,
      status: 'inactive',
      leave_return_date: nil,
      updated_at: 1.day.ago) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: leave_emp,
      profile_status: "leave",
      adp_assoc_oid: "123456") }
    let!(:leave_cancel_emp) {FactoryGirl.create(:employee,
      status: 'inactive',
      leave_return_date: Date.today + 2.days,
      updated_at: 1.day.ago) }
    let!(:lce_profile) {FactoryGirl.create(:profile,
      employee: leave_cancel_emp,
      profile_status: "leave",
      adp_assoc_oid: "123457") }
    let!(:do_nothing_emp) {FactoryGirl.create(:employee,
      status: 'inactive',
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

  describe '#check_new_hire_change' do
    let(:ad)              { double(ActiveDirectoryService) }
    let(:adp)             { AdpService::Workers.new }
    let!(:future_date)    { 1.year.from_now.change(usec: 0) }
    let!(:regular_w_type) { FactoryGirl.create(:worker_type, code: 'FTR') }
    let!(:new_hire) do
      FactoryGirl.create(:employee,
        status: 'pending',
        adp_status:  nil,
        first_name: 'Robert',
        hire_date: Date.new(2017, 7, 12))
    end

    before do
      FactoryGirl.create(:profile,
        employee: new_hire,
        start_date: Date.new(2017, 7, 12),
        adp_assoc_oid: 'G3NQ5754ETA080N',
        adp_employee_id: '100015',
        worker_type: regular_w_type)

      adp.token = 'a-token-value'
      allow(ActiveDirectoryService).to receive(:new).and_return(ads)
      allow(ads).to receive(:update)
      allow(EmployeeWorker).to receive(:perform_async)
      allow(EmployeeChangeWorker).to receive(:perform_async)
    end

    it 'creates sidekiq workers' do
      adp.check_future_changes
      expect(EmployeeChangeWorker).to have_received(:perform_async).with(new_hire.id)
    end

    context 'when worker found' do
      before do
        allow(URI).to receive(:parse)
          .with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        allow(response).to receive(:body).and_return(pending_hire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { 'Accept' => 'application/json',
            'Authorization' => 'Bearer a-token-value',
          }).and_return(response)
        allow(response).to receive(:code)
        allow(response).to receive(:message)

        adp.check_new_hire_change(new_hire)
      end

      it 'updates worker name changes' do
        expect(new_hire.first_name).to eq('Bob')
        expect(new_hire.last_name).to eq('Seger')
      end

      it 'updates worker hire date changes' do
        expect(new_hire.hire_date).to eq(DateTime.new(2018, 7, 12))
      end

      it 'updates AD' do
        expect(ads).to have_received(:update).with([new_hire])
      end

      it 'does not send sec access form' do
        expect(EmployeeWorker).not_to have_received(:perform_async)
      end

      it 'creates an emp delta' do
        expect(new_hire.emp_deltas.last.before['first_name']).to eq('Robert')
        expect(new_hire.emp_deltas.last.after['first_name']).to eq('Bob')
      end

      it 'has the right status' do
        expect(new_hire.status).to eq('pending')
      end

      it 'has the right adp status' do
        expect(new_hire.adp_status).to eq(nil)
      end
    end

    context 'when worker not found' do
      let(:mailer) { double(TechTableMailer) }

      before :each do
        allow(URI).to receive(:parse)
          .with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{future_date.strftime('%m')}%2F#{future_date.strftime('%d')}%2F#{future_date.strftime('%Y')}").and_return(uri)
        allow(response).to receive(:body).and_return(not_found_json)
        allow(http).to receive(:get).with(
          request_uri,
          { 'Accept' => 'application/json',
            'Authorization' => 'Bearer a-token-value',
          }).and_return(response)
        allow(response).to receive(:code)
        allow(response).to receive(:message)
        allow(TechTableMailer).to receive(:alert_email).and_return(mailer)
        allow(mailer).to receive(:deliver_now)

        adp.check_new_hire_change(new_hire)
      end

      it 'does not update AD' do
        expect(ads).not_to have_received(:update)
      end

      it 'sends alert to TechTable' do
        expect(TechTableMailer).to have_received(:alert_email)
          .with("Cannot get updated ADP info for new contract hire #{new_hire.cn}, employee id: #{new_hire.employee_id}.\nPlease contact the developer to help diagnose the problem.")
        expect(mailer).to have_received(:deliver_now)
      end
    end

    context 'worker has contract end date less than one year' do
      let(:adp)                     { AdpService::Workers.new }
      let(:contract_end_date)       { Date.today + 3.months }
      let(:check_contract_end_date) { contract_end_date - 1.day }
      let!(:worker_type) do
        FactoryGirl.create(:worker_type,
          code: 'ACW',
          kind: 'Contractor')
      end

      let!(:new_contractor) do
        FactoryGirl.create(:employee,
          status: 'pending',
          first_name: 'Robert',
          contract_end_date: contract_end_date,
          hire_date: Date.today + 2.weeks)
      end

      before do
        FactoryGirl.create(:profile,
          profile_status: 'pending',
          employee: new_contractor,
          adp_employee_id: '100015',
          adp_assoc_oid: 'G3NQ5754ETA080N',
          worker_type: worker_type)

        adp.token = 'a-token-value'
        allow(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NQ5754ETA080N?asOfDate=#{check_contract_end_date.strftime('%m')}%2F#{check_contract_end_date.strftime('%d')}%2F#{check_contract_end_date.strftime('%Y')}").and_return(uri)
        allow(response).to receive(:body).and_return(contractor_json)
        allow(http).to receive(:get).with(
          request_uri,
          { 'Accept' => 'application/json',
            'Authorization' => 'Bearer a-token-value',
          }).and_return(response)
        allow(response).to receive(:code)
        allow(response).to receive(:message)

        adp.check_new_hire_change(new_contractor)
      end

      it 'updates the worker name' do
        expect(new_contractor.first_name).to eq('Bob')
        expect(new_contractor.last_name).to eq('Seger')
      end

      it 'has the correct status' do
        expect(new_contractor.status).to eq('pending')
      end

      it 'has the correct adp status' do
        expect(new_contractor.adp_status).to eq(nil)
      end

      it 'should should update data for worker' do
        expect(new_contractor.profiles.count).to eq(1)
        expect(new_contractor.current_profile.profile_status).to eq('pending')
      end
    end

    context 'when rehire' do
      let(:adp)     { AdpService::Workers.new }
      let!(:ptt_wt) { FactoryGirl.create(:worker_type, code: 'PTT') }
      let!(:jt)     { FactoryGirl.create(:job_title, code: 'BRDSRNE') }
      let!(:dept)   { FactoryGirl.create(:department, code: '063050') }
      let!(:rehire) do
        FactoryGirl.create(:employee,
          status: 'pending',
          hire_date: Date.new(2016, 10, 26))
      end

      before do
        adp.token = "a-token-value"
        FactoryGirl.create(:profile,
          profile_status: 'terminated',
          employee: rehire,
          start_date: Date.new(2016, 10, 26),
          end_date: Date.new(2016, 12, 9),
          adp_assoc_oid: 'G3NGJ6TFKN7ZWHBP',
          adp_employee_id: '102058',
          worker_type: ptt_wt,
          primary: false)
        FactoryGirl.create(:profile,
          profile_status: 'pending',
          employee: rehire,
          start_date: Date.new(2017, 11, 1),
          adp_assoc_oid: 'G3NGJ6TFKN7ZWHBP',
          adp_employee_id: '102058',
          worker_type: ptt_wt)

        check_date = 1.year.from_now.change(:usec => 0)
        allow(URI).to receive(:parse).with("https://api.adp.com/hr/v2/workers/G3NGJ6TFKN7ZWHBP?asOfDate=#{check_date.strftime('%m')}%2F#{check_date.strftime('%d')}%2F#{check_date.strftime('%Y')}").and_return(uri)
        allow(response).to receive(:body).and_return(pend_rehire_json)
        allow(http).to receive(:get).with(
          request_uri,
          { "Accept"=>"application/json",
            "Authorization"=>"Bearer a-token-value",
          }).and_return(response)
        allow(response).to receive(:code)
        allow(response).to receive(:message)

        adp.check_new_hire_change(rehire)
      end

      it 'has the original hire date' do
        expect(rehire.hire_date).to eq(Date.new(2016, 10, 26))
      end

      it 'has nil for termination date' do
        expect(rehire.termination_date).to eq(nil)
      end

      it 'has two profiles' do
        expect(rehire.profiles.count).to eq(2)
      end

      it 'has the correct status' do
        expect(rehire.status).to eq('pending')
      end

      it 'has the correct adp status' do
        expect(rehire.adp_status).to eq(nil)
      end

      it 'has the right current profile' do
        expect(rehire.current_profile.profile_status).to eq('pending')
      end

      it 'has the correct profile start and end dates' do
        expect(rehire.profiles.terminated.reorder(:created_at).last.start_date).to eq(Date.new(2016, 10, 26))
        expect(rehire.profiles.terminated.reorder(:created_at).last.end_date).to eq(Date.new(2016, 12, 9))
        expect(rehire.profiles.pending.reorder(:created_at).last.start_date).to eq(Date.new(2017, 10, 16))
        expect(rehire.profiles.pending.reorder(:created_at).last.end_date).to eq(nil)
      end
    end
  end
end
