require 'rails_helper'

describe AdpService::Events, type: :service do
  let(:url)         { 'https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials' }
  let(:uri)         { double(URI) }
  let(:host)        { 'accounts.adp.com' }
  let(:port)        { 443 }
  let(:request_uri) { '/auth/oauth/v2/token?grant_type=client_credentials' }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }
  let(:header_hash) do
    {
      'server' => ['Apache-Coyote/1.1'],
      'adp-correlationid' => ['ac5c8427-d7df-4a36-9c1c-ed9a9405e58f'],
      'content-language' => ['en-US'],
      'adp-msg-msgid' => ['0x_414d51205554494e464f4251362020206f3e8b5866814928'],
      'etag' => ["W/\"298-3FGDAYibwmNEuawCuC+BEg\""],
      'x-upstream' => ['10.136.1.43:4110'],
      'strict-transport-security' => ['max-age=31536000'],
      'content-type' => ['application/json;charset=utf-8'],
      'content-length' => ['664'],
      'date' => ['Fri, 10 Feb 2017 00:57:40 GMT'], 'connection' => ['close']
    }
  end
  let(:json)                { JSON.dump(JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/adp_event.json'))) }
  let(:hire_json)           { File.read(Rails.root.to_s + '/spec/fixtures/adp_hire_event.json') }
  let(:contract_hire_json)  { File.read(Rails.root.to_s + '/spec/fixtures/adp_contract_hire_event.json') }
  let(:term_json)           { File.read(Rails.root.to_s + '/spec/fixtures/adp_terminate_event.json') }
  let(:leave_json)          { File.read(Rails.root.to_s + '/spec/fixtures/adp_leave_event.json') }
  let(:rehire_json)         { File.read(Rails.root.to_s + '/spec/fixtures/adp_rehire_event.json') }
  let(:cat_change_json)     { File.read(Rails.root.to_s + '/spec/fixtures/adp_cat_change_hire_event.json') }
  let(:ads) { double(ActiveDirectoryService) }
  let(:adp) { AdpService::Events.new }

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
      'Accept' => 'application/json',
      'Authorization' => "Basic #{SECRETS.adp_creds}"
    ).and_return(response)
    expect(response).to receive(:body).once.and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  it 'should get a bearer token from ADP' do
    expect(AdpService::Events.new.token).to eq('7890f85c-43ef-4ebc-acb7-f98f2c0581d0')
  end

  before do
    allow(URI).to receive(:parse).with('https://api.adp.com/core/v1/event-notification-messages').and_return(uri)
    allow(http).to receive(:get).with(
      request_uri,
      'Accept' => 'application/json',
      'Authorization' => 'Bearer a-token-value'
      ).and_return(response)
  end

  describe '#get_events' do
    it 'processes event if body is present and call itself until nil' do
      expect(response).to receive(:body).ordered.and_return(json)
      expect(response).to receive(:body).ordered.and_return(json)
      expect(response).to receive(:body).ordered.and_return(nil)

      adp.token = 'a-token-value'

      expect(adp).to receive(:process_event).twice.and_return(true)
      expect(adp).to receive(:get_events).exactly(3).times.and_call_original

      adp.get_events
    end

    it 'returns false if response is nil' do
      expect(response).to receive(:body).ordered.and_return(nil)

      adp.token = 'a-token-value'

      expect(adp).to_not receive(:process_event)
      expect(adp.get_events).to eq(false)
    end
  end

  describe '#process_event' do
    let(:ae) { double(AdpEvent) }

    it 'creates AdpEvent with correct values' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:sort_event)
      expect {
        adp.process_event(header_hash, json)
      }.to change{ AdpEvent.count }.from(0).to(1)
      expect(AdpEvent.last.json).to eq(json)
      expect(AdpEvent.last.msg_id).to eq('0x_414d51205554494e464f4251362020206f3e8b5866814928')
      expect(AdpEvent.last.status).to eq('new')
    end

    it 'scrubs sensitive data' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:sort_event)
      expect {
        adp.process_event(header_hash, hire_json)
      }.to change{AdpEvent.count}.from(0).to(1)
      expect(
        JSON.parse(AdpEvent.last.json)['events'][0]['data']['output']['worker']['person']['governmentIDs'][0]['idValue']
      ).to eq('REDACTED')
    end

    it 'returns false if AdpEvent does not save' do
      allow(AdpEvent).to receive(:new).and_return(ae)
      allow(ae).to receive(:save).and_return(false)

      adp.token = 'a-token-value'

      expect(adp).to_not receive(:sort_event)
      expect(adp.process_event(header_hash, json)).to eq(false)
    end
  end

  describe '#sort_event' do
    let(:adp_event)           { FactoryGirl.create(:adp_event, json: JSON.dump(json)) }
    let(:hire_event)          { FactoryGirl.create(:adp_event, kind: 'worker.hire') }
    let(:contract_hire_event) { FactoryGirl.create(:adp_event,
                                kind: 'worker.hire',
                                json: JSON.dump(contract_hire_json)) }
    let(:term_event)          { FactoryGirl.create(:adp_event,
                                kind: 'worker.terminate',
                                json: JSON.dump(term_json)) }
    let(:leave_event)         { FactoryGirl.create(:adp_event,
                                kind: 'worker.on-leave',
                                json: JSON.dump(leave_json)) }

    it 'processes hire for new hire' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:process_hire).and_return(true)
      expect(adp).to receive(:del_event).with(hire_event.msg_id)
      expect(hire_event).to receive(:process!)

      adp.sort_event(hire_event)
    end

    it 'processes hire for contract hire' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:process_hire).and_return(true)
      expect(adp).to receive(:del_event).with(contract_hire_event.msg_id)
      expect(contract_hire_event).to receive(:process!)

      adp.sort_event(contract_hire_event)
    end

    it 'processes term for term' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:process_term).and_return(true)
      expect(adp).to receive(:del_event).with(term_event.msg_id)
      expect(term_event).to receive(:process!)

      adp.sort_event(term_event)
    end

    it 'processes leave for leave' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:process_leave).and_return(true)
      expect(adp).to receive(:del_event).with(leave_event.msg_id)
      expect(leave_event).to receive(:process!)

      adp.sort_event(leave_event)
    end

    it 'deletes event for anything else' do
      adp.token = 'a-token-value'

      expect(adp).to receive(:del_event).with(adp_event.msg_id)

      adp.sort_event(adp_event)
    end
  end

  describe '#process_hire' do
    let!(:worker_type)      { FactoryGirl.create(:worker_type,
                              code: 'OLFR',
                              kind: 'Regular') }
    let!(:cont_worker_type) { FactoryGirl.create(:worker_type,
                              code: 'CONT',
                              kind: 'Contractor') }
    let(:application)       { FactoryGirl.create(:application,
                              name: 'Security Group') }
    let(:regular_al)        { FactoryGirl.create(:access_level,
                              name: 'OT Regular Workers',
                              application_id: application.id) }
    let!(:regular_sp)       { FactoryGirl.create(:security_profile,
                              name: 'Basic Regular Worker Profile') }
    let!(:contract_sp)      { FactoryGirl.create(:security_profile,
                              name: 'Basic Contract Worker Profile') }
    let!(:regular_spal)     { FactoryGirl.create(:sec_prof_access_level,
                              security_profile_id: regular_sp.id,
                              access_level_id: regular_al.id) }
    let(:sec_access_service){ double(SecAccessService) }
    let(:manager)           { FactoryGirl.create(:active_employee) }
    let!(:manager_profile)  { FactoryGirl.create(:active_profile,
                              employee: manager,
                              adp_employee_id: '654321') }
    let(:onboard_service)   { double(EmployeeService::Onboard) }

    before :each do
      allow(EmployeeService::Onboard).to receive(:new).and_return(onboard_service)
      allow(onboard_service).to receive(:new_worker)
      allow(onboard_service).to receive(:send_manager_form)
      allow(ads).to receive(:modify_sec_group)
      allow(ads).to receive(:scan_for_failed_ldap_transactions)
      allow(ads).to receive(:create_disabled_accounts)
      allow(ActiveDirectoryService).to receive(:new).and_return(ads)
    end

    context 'when regular hire' do
      it 'creates Employee w/ pending status' do
        adp.token = 'a-token-value'
        event = FactoryGirl.create(:adp_event,
          status: 'new',
          json: hire_json
        )

        expect{
          adp.process_hire(event)
        }.to change { Employee.count }.by(1)
        expect(Employee.reorder(:created_at).last.employee_id).to eq('if0rcdig4')
        expect(Employee.reorder(:created_at).last.status).to eq('pending')
      end
    end

    context 'when contractor' do
      it 'creates employee with worker end date' do
        adp.token = 'a-token-value'

        event = FactoryGirl.create(:adp_event,
          status: 'new',
          json: contract_hire_json
        )

        expect{
          adp.process_hire(event)
        }.to change{ Employee.count }.by(1)
        expect(Employee.reorder(:created_at).last.employee_id).to eq('8vheos3zl')
        expect(Employee.reorder(:created_at).last.status).to eq('pending')
        expect(Employee.reorder(:created_at).last.contract_end_date).to eq('2017-12-01')
      end
    end

    context 'when category change or rehire' do
      let!(:acw_wt)          { FactoryGirl.create(:worker_type, code: 'ACW') }
      let!(:regular_sp)      { FactoryGirl.create(:security_profile, name: 'Basic Regular Worker Profile') }
      let(:manager)          { FactoryGirl.create(:active_employee) }
      let!(:manager_profile) { FactoryGirl.create(:active_profile,
                               employee: manager,
                               adp_employee_id: '101836') }

      it 'does not create a new worker' do
        adp.token = 'a-token-value'

        event = FactoryGirl.create(:adp_event,
          status: 'new',
          json: cat_change_json
        )

        expect{
          adp.process_hire(event)
        }.not_to change { Employee.count }
        expect(event.status).to eq('new')
      end

      it 'sends an onboarding form with event' do
        adp.token = 'a-token-value'

        event = FactoryGirl.create(:adp_event,
          status: 'new',
          json: cat_change_json
        )
        expect(EmployeeWorker).to receive(:perform_async)
        expect{
          adp.process_hire(event)
        }.not_to change { Employee.count }
      end
    end
  end

  describe '#process_term' do
    let(:mailer)          { double(TechTableMailer) }
    let(:manager_mailer)  { double(ManagerMailer) }
    let!(:event)          { FactoryGirl.create(:adp_event,
                            kind: 'worker.terminate',
                            json: term_json) }
    let!(:adp)            { AdpService::Events.new }

    before :each do
      Timecop.freeze(Time.new(2017, 1, 1, 1, 0, 0))
      adp.token = 'a-token-value'
      allow(ActiveDirectoryService).to receive(:new).and_return(ads)
      allow(ads).to receive(:update)
      allow(TechTableMailer).to receive(:offboard_notice).and_return(mailer)
      allow(mailer).to receive(:deliver_now)
      allow(EmployeeWorker).to receive(:perform_async)
      allow(adp).to receive(:job_change?).and_return(false)
    end

    after :each do
      Timecop.return
    end

    context 'when standard termination' do
      let(:manager)     { FactoryGirl.create(:active_employee) }
      let!(:term_emp)   { FactoryGirl.create(:active_employee,
                          termination_date: nil,
                          manager: manager) }
      let!(:profile)    { FactoryGirl.create(:active_profile,
                          employee: term_emp,
                          adp_employee_id: '101652') }

      before do
        adp.process_term(event)
      end

      it 'updates termination date' do
        expect(term_emp.reload.termination_date).to eq('2017-01-24')
      end

      it 'updates position end date' do
        expect(profile.reload.end_date).to eq('2017-01-24')
      end

      it 'creates emp delta with termination dates' do
        expect(term_emp.emp_deltas.count).to eq(1)
        expect(term_emp.emp_deltas.last.before).to eq({
          'end_date'=>nil,
          'termination_date'=>nil
        })
        expect(term_emp.emp_deltas.last.after).to eq({
          'end_date'=>'2017-01-24 00:00:00 UTC',
          'termination_date'=>'2017-01-24 00:00:00 UTC'
        })
      end

      it 'sends manager onboard form' do
        expect(EmployeeWorker).to have_received(:perform_async)
      end

      it 'sends TechTable upcoming termination notice' do
        expect(mailer).to have_received(:deliver_now)
      end

      it 'updates request status' do
        expect(term_emp.reload.request_status).to eq('waiting')
      end

      it 'does not set offboarded_at date' do
        expect(term_emp.offboarded_at).to eq(nil)
      end
    end

    context 'when previously offboarded contractor' do
      let!(:contractor) { FactoryGirl.create(:employee,
                          status: 'terminated',
                          contract_end_date: Date.new(2017, 01, 25),
                          termination_date: nil,
                          offboarded_at: DateTime.new(2017, 1, 27, 3, 3, 0, '+00:00'),
                          request_status: 'none') }
      let!(:profile)    { FactoryGirl.create(:profile,
                          profile_status: 'terminated',
                          end_date: Date.new(2017, 01, 25),
                          employee: contractor,
                          adp_employee_id: '101652') }
      let!(:event)      { FactoryGirl.create(:adp_event,
                          kind: 'worker.terminate',
                          json: term_json) }

      before :each do
        Timecop.freeze(Time.new(2017, 2, 2, 2, 0, 0, '+00:00'))
        adp.token = 'a-token-value'
        allow(adp).to receive(:job_change?).and_return(false)
        adp.process_term(event)
      end

      after :each do
        Timecop.return
      end

      it 'is not a job change' do
        expect(adp.job_change?(contractor, '2017-01-24')).to be(false)
      end

      it 'updates termination date' do
        expect(contractor.reload.termination_date).to eq('2017-01-24')
      end

      it 'updates profile end date' do
        expect(profile.reload.end_date).to eq('2017-01-24')
      end

      it 'creates emp delta' do
        expect(contractor.emp_deltas.last.before).to eq({
          'end_date' => '2017-01-25 00:00:00 UTC',
          'termination_date' => nil
        })
        expect(contractor.emp_deltas.last.after).to eq({
          'end_date' => '2017-01-24 00:00:00 UTC',
          'termination_date'=>'2017-01-24 00:00:00 UTC'
        })
      end

      it 'does not change status' do
        expect(contractor.status).to eq('terminated')
      end

      it 'does not change request status' do
        expect(contractor.request_status).to eq('none')
      end

      it 'does not change offboarded_at date' do
        expect(contractor.offboarded_at).to eq("2017-01-27 03:03:00.000000000 +0000")
      end
    end

    context 'when contractor in offboarding period' do
      let!(:event)      { FactoryGirl.create(:adp_event,
                          kind: 'worker.terminate',
                          json: term_json) }

      before do
        Timecop.freeze(Time.new(2017, 01, 22, 2, 0, 0, '+00:00'))
      end

      after do
        Timecop.return
      end

      context 'when offboarding form not completed' do
        let!(:contractor) { FactoryGirl.create(:employee,
                            status: 'active',
                            contract_end_date: Date.new(2017, 01, 25),
                            termination_date: nil,
                            request_status: 'waiting') }
        let!(:profile)    { FactoryGirl.create(:profile,
                            profile_status: 'active',
                            end_date: nil,
                            employee: contractor,
                            adp_employee_id: '101652') }

        before do
          adp.process_term(event)
        end

        it 'does not change request status' do
          expect(contractor.reload.request_status).to eq('waiting')
        end

        it 'updates termination date' do
          expect(contractor.reload.termination_date).to eq('2017-01-24')
        end

        it 'updates position end date' do
          expect(profile.reload.end_date).to eq('2017-01-24')
        end

        it 'creates emp delta with termination dates' do
          expect(contractor.emp_deltas.count).to eq(1)
          expect(contractor.emp_deltas.last.before).to eq({
            'end_date'=>nil,
            'termination_date'=>nil
          })
          expect(contractor.emp_deltas.last.after).to eq({
            'end_date'=>'2017-01-24 00:00:00 UTC',
            'termination_date'=>'2017-01-24 00:00:00 UTC'
          })
        end

        it 'sends manager onboard form' do
          expect(EmployeeWorker).to have_received(:perform_async)
        end

        it 'sends TechTable upcoming termination notice' do
          expect(mailer).to have_received(:deliver_now)
        end

        it 'does not set offboarded_at date' do
          expect(contractor.offboarded_at).to eq(nil)
        end
      end

      context 'when offboarding form completed' do
        let!(:contractor) { FactoryGirl.create(:employee,
                            status: 'active',
                            contract_end_date: Date.new(2017, 01, 25),
                            termination_date: nil,
                            request_status: 'completed') }
        let!(:profile)    { FactoryGirl.create(:profile,
                            profile_status: 'active',
                            end_date: nil,
                            employee: contractor,
                            adp_employee_id: '101652') }

        before do
          adp.process_term(event)
        end

        it 'does not change request status' do
          expect(contractor.reload.request_status).to eq('completed')
        end

        it 'updates termination date' do
          expect(contractor.reload.termination_date).to eq('2017-01-24')
        end

        it 'updates position end date' do
          expect(profile.reload.end_date).to eq('2017-01-24')
        end

        it 'creates emp delta with termination dates' do
          expect(contractor.emp_deltas.count).to eq(1)
          expect(contractor.emp_deltas.last.before).to eq({
            'end_date'=>nil,
            'termination_date'=>nil
          })
          expect(contractor.emp_deltas.last.after).to eq({
            'end_date'=>'2017-01-24 00:00:00 UTC',
            'termination_date'=>'2017-01-24 00:00:00 UTC'
          })
        end

        it 'does not send manager form' do
          expect(EmployeeWorker).not_to have_received(:perform_async)
        end

        it 'does not send TechTable notice' do
          expect(TechTableMailer).not_to have_received(:offboard_notice)
        end

        it 'does not set offboarded_at date' do
          expect(contractor.offboarded_at).to eq(nil)
        end
      end
    end

    context 'when employee not found' do
      let!(:event) do
        FactoryGirl.create(:adp_event,
          kind: 'worker.terminate',
          json: term_json)
      end

      it 'does nothing' do
        adp.process_term(event)
        expect(event.reload.status).to eq('new')
      end
    end

    context 'when termination date in past' do
      let(:mailer)    { double(TechTableMailer) }
      let!(:term_emp) { FactoryGirl.create(:active_employee, termination_date: nil) }
      let!(:profile) do
        FactoryGirl.create(:active_profile,
          employee: term_emp,
          adp_employee_id: '101652')
      end

      before do
        FactoryGirl.create(:adp_event,
          kind: 'worker.terminate',
          json: term_json)
        Timecop.freeze(Time.new(2017, 1, 27, 2, 0, 0, '+00:00'))
        allow(ActiveDirectoryService).to receive(:new).and_return(ads)
        allow(ads).to receive(:update).with([term_emp])
        allow(ads).to receive(:deactivate).with([term_emp])
        allow(TechTableMailer).to receive(:offboard_instructions).and_return(mailer)
        allow(mailer).to receive(:deliver_now)

        adp.token = 'a-token-value'
        allow(adp).to receive(:job_change?).and_return(false)
        adp.process_term(event)
      end

      after do
        Timecop.return
      end

      it 'terminates worker' do
        expect(term_emp.reload.status).to eq('terminated')
      end

      it 'terminates profile' do
        expect(profile.reload.profile_status).to eq('terminated')
      end

      it 'does not change request status' do
        expect(term_emp.reload.request_status).to eq('none')
      end

      it 'updates termination date' do
        expect(term_emp.reload.termination_date).to eq('2017-01-24')
      end

      it 'updates position end date' do
        expect(profile.reload.end_date).to eq('2017-01-24')
      end

      it 'creates one emp delta' do
        expect(term_emp.emp_deltas.count).to eq(1)
      end

      it 'creates emp delta with before data' do
        expect(term_emp.emp_deltas.last.before).to eq(
          'end_date' => nil,
          'termination_date' => nil
        )
      end

      it 'creates emp delta with after data' do
        expect(term_emp.emp_deltas.last.after).to eq(
          'end_date' => '2017-01-24 00:00:00 UTC',
          'termination_date' => '2017-01-24 00:00:00 UTC'
        )
      end

      it 'updates worker info in Active Directory' do
        expect(ads).to have_received(:update).with([term_emp])
      end

      it 'deactivates worker in Active Directory' do
        expect(ads).to have_received(:deactivate).with([term_emp])
      end

      it 'sends TechTable termination instructions' do
        expect(mailer).to have_received(:deliver_now)
      end

      it 'sets offboarded_at date' do
        expect(term_emp.reload.offboarded_at).to eq(Time.new(2017, 1, 27, 2, 0, 0, '+00:00'))
      end
    end
  end

  describe '#process_leave' do
    let(:event) do
      FactoryGirl.create(:adp_event,
        kind: 'worker.on-leave',
        json: leave_json)
    end

    context 'when worker found' do
      let!(:leave_emp) do
        FactoryGirl.create(:active_employee, leave_start_date: nil)
      end

      before do
        FactoryGirl.create(:active_profile,
          employee: leave_emp,
          adp_employee_id: '100344')
      end

      context 'when future leave date' do
        before do
          Timecop.freeze(Time.new(2017, 1, 1, 5, 0, 0, '-07:00'))
          adp.process_leave(event)
        end

        after do
          Timecop.return
        end

        it 'updates leave start date' do
          expect(leave_emp.reload.leave_start_date).to eq('2017-01-23')
        end

        it 'creates emp delta with before data' do
          expect(leave_emp.emp_deltas.last.before).to eq('leave_start_date' => nil)
        end

        it 'creates emp delta with after data' do
          expect(leave_emp.emp_deltas.last.after).to eq('leave_start_date' => '2017-01-23 00:00:00 UTC')
        end
      end

      context 'when leave date in the past' do
        before do
          allow(ActiveDirectoryService).to receive(:new).and_return(ads)
          allow(ads).to receive(:deactivate)
          adp.process_leave(event)
        end

        it 'deactivates AD account' do
          expect(ads).to have_received(:deactivate).with([leave_emp])
        end

        it 'updates worker status' do
          expect(leave_emp.reload.status).to eq('inactive')
        end

        it 'updates profile status' do
          expect(leave_emp.reload.current_profile.profile_status).to eq('leave')
        end

        it 'sets leave date' do
          expect(leave_emp.reload.leave_start_date).to eq('2017-01-23')
        end

        it 'creates emp data with before data' do
          expect(leave_emp.emp_deltas.last.before).to eq('leave_start_date' => nil)
        end

        it 'creates emp data with after data' do
          expect(leave_emp.emp_deltas.last.after).to eq('leave_start_date' => '2017-01-23 00:00:00 UTC')
        end
      end
    end

    context 'when worker not found' do
      it 'returns false' do
        expect(adp.process_leave(event)).to be(false)
      end
    end
  end

  describe '#process_rehire' do
    let(:event) do
      FactoryGirl.create(:adp_event,
        status: 'new',
        json: rehire_json)
    end

    before do
      allow(EmployeeWorker).to receive(:perform_async)
      adp.token = 'a-token-value'
    end

    context 'when worker does not have a mezzo record' do
      before do
        FactoryGirl.create(:security_profile, name: 'Basic Regular Worker Profile')
      end

      it 'does not create a new employee record' do
        expect { adp.process_rehire(event) }.not_to change(Employee, :count)
      end

      it 'does not process event' do
        adp.process_rehire(event)
        expect(event.reload.status).to eq('new')
      end

      it 'sends manager onboarding form' do
        adp.process_rehire(event)
        expect(EmployeeWorker).to have_received(:perform_async)
      end
    end

    context 'when worker has a mezzo record' do
      let(:rehired_emp) do
        FactoryGirl.create(:employee,
          status: 'terminated',
          request_status: 'none',
          hire_date: Date.new(2010, 9, 1),
          termination_date: Date.new(2017, 1, 1))
      end

      before do
        FactoryGirl.create(:worker_type,
          code: 'FTR',
          kind: 'Regular')
        FactoryGirl.create(:terminated_profile,
          start_date: Date.new(2010, 9, 1),
          end_date: Date.new(2017, 1, 1),
          employee: rehired_emp,
          adp_employee_id: '123456')
        allow(ActiveDirectoryService).to receive(:new).and_return(ads)
        allow(ads).to receive(:update)
        adp.process_rehire(event)
      end

      it 'does not create a new employee record' do
        expect { adp.process_rehire(event) }.not_to(change(Employee, :count))
      end

      it 'creates a new profile' do
        expect(rehired_emp.reload.profiles.count).to eq(2)
      end

      it 'has the correct employee status' do
        expect(rehired_emp.reload.status).to eq('pending')
      end

      it 'has the correct request status' do
        expect(rehired_emp.reload.request_status).to eq('waiting')
      end

      it 'clears the termination date' do
        expect(rehired_emp.reload.termination_date).to eq(nil)
      end

      it 'maintains the original hire date' do
        expect(rehired_emp.reload.hire_date).to eq(Date.new(2010, 9, 1))
      end

      it 'has a terminated profile' do
        expect(rehired_emp.profiles.terminated.count).to eq(1)
      end

      it 'has a pending profile' do
        expect(rehired_emp.profiles.pending.count).to eq(1)
      end

      it 'has the new job title' do
        expect(rehired_emp.reload.job_title.code).to eq('SPMASR')
      end

      it 'has the new location' do
        expect(rehired_emp.reload.location.code).to eq('SF')
      end

      it 'updates Active Directory' do
        expect(ads).to have_received(:update).with([rehired_emp])
      end

      it 'sends the manager form' do
        expect(EmployeeWorker).to have_received(:perform_async)
      end
    end
  end
end
