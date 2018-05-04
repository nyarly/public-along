require 'rails_helper'
require 'rake'

describe 'employee rake tasks', type: :tasks do

  let!(:london)      { Location.find_by(name: 'London Office') }
  let!(:sf)          { Location.find_by(name: 'San Francisco Headquarters') }
  let!(:la)          { Location.find_by(name: 'Los Angeles Office') }
  let!(:mumbai)      { Location.find_by(name: 'Mumbai Office') }
  let!(:melbourne)   { Location.find_by(name: 'Melbourne Office') }
  let!(:illinois)    { Location.find_by(name: 'Illinois') }
  let!(:worker_type) { FactoryGirl.create(:worker_type, kind: 'Regular') }
  let!(:contract_wt) { FactoryGirl.create(:worker_type, kind: 'Contractor') }
  let!(:manager)     { FactoryGirl.create(:employee) }

  let(:mailer) { double(ManagerMailer) }

  before do
    Rake.application = Rake::Application.new
    Rake.application.rake_require 'lib/tasks/employee', [Rails.root.to_s], ''
    Rake::Task.define_task :environment
  end

  describe '#employee:change_status' do
    let(:ldap)       { double(Net::LDAP) }
    let(:ldap_entry) { double(Net::LDAP::Entry) }
    let(:off_serv)   { instance_double(EmployeeService::Offboard) }

    let(:new_hire_uk) do
      FactoryGirl.create(:employee,
        status: 'pending',
        hire_date: Date.new(2016, 7, 29),
        request_status: 'completed')
    end

    let!(:nh_uk_prof) do
      FactoryGirl.create(:profile,
       employee: new_hire_uk,
       start_date: Date.new(2016, 7, 29),
       worker_type: worker_type,
       location: london)
    end

    let(:returning_uk) do
      FactoryGirl.create(:employee,
        status: 'inactive',
        hire_date: Date.new(2016, 1, 1),
        leave_return_date: Date.new(2016, 7, 29))
    end

    let!(:r_uk_prof) do
      FactoryGirl.create(:profile,
        profile_status: 'leave',
        start_date: Date.new(2017, 1, 1),
        employee: returning_uk,
        location: london)
    end

    let(:contract_uk) do
      FactoryGirl.create(:employee,
        status: 'pending',
        hire_date: Date.new(2016, 7, 29),
        contract_end_date: Date.new(2019, 7, 29),
        request_status: 'completed')
    end

    let!(:c_uk_prof) do
      FactoryGirl.create(:profile,
        start_date: Date.new(2016, 7, 29),
        worker_type: contract_wt,
        employee: contract_uk,
        location: london)
    end

    let(:uk_term) do
      FactoryGirl.create(:employee,
        status: 'active',
        termination_date: Date.new(2016, 7, 29))
    end

    let!(:uk_term_prof) do
      FactoryGirl.create(:profile,
        profile_status: 'active',
        start_date: Date.new(2016, 7, 29),
        employee: uk_term,
        location: london)
    end

    let(:new_hire_us) do
      FactoryGirl.create(:employee,
        status: 'pending',
        hire_date: Date.new(2016, 7, 29),
        request_status: 'completed')
    end

    let!(:nh_us_prof) do
      FactoryGirl.create(:profile,
        start_date: Date.new(2016, 7, 29),
        employee: new_hire_us,
        location: sf)
    end

    let(:returning_us) do
      FactoryGirl.create(:employee,
        status: 'inactive',
        hire_date: 1.year.ago,
        leave_return_date: Date.new(2016, 7, 29))
    end

    let!(:r_us_prof) do
      FactoryGirl.create(:profile,
        profile_status: 'leave',
        employee: returning_us,
        location: sf)
    end

    let(:rehire) do
      FactoryGirl.create(:employee,
        status: 'pending',
        request_status: 'completed',
        hire_date: Date.new(2016, 1, 1))
    end

    let!(:rh_old_prof) do
      FactoryGirl.create(:profile,
        profile_status: 'terminated',
        primary: false,
        employee: rehire,
        start_date: Date.new(2016, 1, 1),
        end_date: Date.new(2016, 2, 1))
    end

    let!(:rh_new_prof) do
      FactoryGirl.create(:profile,
        employee: rehire,
        start_date: Date.new(2016, 7, 29))
    end

    let(:us_term) do
      FactoryGirl.create(:employee,
        status: 'active',
        hire_date: 5.years.ago,
        termination_date: Date.new(2016, 7, 29))
    end

    let!(:t_us_prof) do
      FactoryGirl.create(:profile,
        employee: us_term,
        profile_status: 'active',
        location: sf)
    end

    before do
      allow(Net::LDAP).to receive(:new).and_return(ldap)
      allow(ldap).to receive(:host=)
      allow(ldap).to receive(:port=)
      allow(ldap).to receive(:encryption)
      allow(ldap).to receive(:auth)
      allow(ldap).to receive(:bind)
      allow(ldap).to receive(:get_operation_result)
    end

    after do
      Timecop.return
    end

    it 'calls ldap and update only GB new hires and returning leave workers at 3am BST' do
      # 7/29/2016 at 3am BST/2am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 2, 0, 0, '+00:00'))

      expect(ldap).to receive(:replace_attribute).once.with(
        new_hire_uk.dn, :userAccountControl, '512'
      )
      expect(ldap).to receive(:replace_attribute).once.with(
        returning_uk.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        returning_us.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        contract_uk.dn, :userAccountControl, '514'
      )

      Rake::Task['employee:change_status'].invoke

      expect(new_hire_uk.reload.status).to eq('active')
      expect(returning_uk.reload.status).to eq('active')
      expect(contract_uk.reload.status).to eq('active')
      expect(new_hire_us.reload.status).to eq('pending')
      expect(returning_us.reload.status).to eq('inactive')
    end

    it 'calls ldap and update only US new hires and returning leave workers at 3am PST' do

      # 7/29/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 10, 0, 0, '+00:00'))

      expect(ldap).to receive(:replace_attribute).once.with(
        new_hire_us.dn, :userAccountControl, '512'
      )
      expect(ldap).to receive(:replace_attribute).once.with(
       returning_us.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        new_hire_uk.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        returning_uk.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        uk_term.dn, :userAccountControl, '514'
      )
      expect(ldap).to receive(:replace_attribute).once.with(
        rehire.dn, :userAccountControl, '512'
      )

      allow(ldap).to receive(:get_operation_result)
      Rake::Task['employee:change_status'].invoke

      expect(new_hire_us.reload.status).to eq('active')
      expect(returning_us.reload.status).to eq('active')
      expect(new_hire_uk.reload.status).to eq('pending')
      expect(returning_uk.reload.status).to eq('inactive')
      expect(uk_term.reload.status).to eq('active')
      expect(rehire.reload.status).to eq('active')
      expect(rh_old_prof.reload.profile_status).to eq('terminated')
      expect(rh_new_prof.reload.profile_status).to eq('active')
    end

    context 'when 9pm PST' do
      let(:contract_end_us) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'bb',
          hire_date: 5.years.ago,
          contract_end_date: Date.new(2016, 7, 29),
          manager: manager)
      end

      let!(:t_prof) do
        FactoryGirl.create(:profile,
          profile_status: 'active',
          employee: contract_end_us,
          start_date: 5.years.ago,
          location: sf)
      end

      let(:leave_us) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'cc',
          hire_date: 2.years.ago,
          leave_start_date: Date.new(2016, 7, 30),
          manager: manager)
      end

      let!(:l_prof) do
        FactoryGirl.create(:profile,
          profile_status: 'active',
          start_date: 5.years.ago,
          employee: leave_us,
          location: sf)
      end

      before do
        # 7/29/2016 at 9pm PST/3am UTC
        Timecop.freeze(Time.new(2016, 7, 30, 4, 03, 0, '+00:00'))

        allow(ldap).to receive(:search).and_return([ldap_entry])
        allow(ldap_entry).to receive(:dn).and_return('the old dn')
      end

      after do
        Timecop.return
      end

      it 'calls ldap and update only terminations or workers on leave at 9pm in PST' do
        expect(ldap).to receive(:replace_attribute).thrice.with(
          'the old dn', :userAccountControl, '514'
        )

        expect(ldap).to receive(:rename).once.with({
          :olddn=>'the old dn',
          :newrdn=>"cn=#{us_term.cn}",
          :delete_attributes=>true,
          :new_superior=>'ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com'})

        expect(ldap).to receive(:rename).once.with({
          :olddn=>'the old dn',
          :newrdn=>"cn=#{contract_end_us.cn}",
          :delete_attributes=>true,
          :new_superior=>'ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com'})

        expect(ldap).to receive(:rename).once.with({
          :olddn=>'the old dn',
          :newrdn=>"cn=#{leave_us.cn}",
          :delete_attributes=>true,
          :new_superior=>'ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com'})

        allow(ldap).to receive(:get_operation_result)

        Rake::Task['employee:change_status'].invoke

        expect(us_term.reload.status).to eq('terminated')
        expect(t_us_prof.reload.profile_status).to eq('terminated')
        expect(contract_end_us.reload.status).to eq('terminated')
        expect(t_prof.reload.profile_status).to eq('terminated')
        expect(leave_us.reload.status).to eq('inactive')
        expect(l_prof.reload.profile_status).to eq('leave')
      end
    end

    it 'calls ldap and update only terminations, contract ends, or workers on leave at 9pm in IST' do
      contract_end = FactoryGirl.create(:employee,
        status: 'active',
        hire_date: Date.new(2014, 5, 3),
        contract_end_date: Date.new(2016, 7, 29),
        manager: manager)
      ce_profile = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: contract_end,
        department_id: Department.find_by(:name => 'Technology/CTO Admin').id,
        location_id: mumbai.id)
      termination = FactoryGirl.create(:employee,
        status: 'active',
        hire_date: Date.new(2014, 5, 3),
        termination_date: Date.new(2016, 7, 29))
      term_profile = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: termination,
        department_id: Department.find_by(:name => 'Technology/CTO Admin').id,
        location_id: mumbai.id)
      leave = FactoryGirl.create(:employee,
        status: 'active',
        hire_date: Date.new(2014, 5, 3),
        leave_start_date: Date.new(2016, 7, 30))
      leave_profile = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: leave,
        department_id: Department.find_by(:name => 'Infrastructure Engineering').id,
        location_id: mumbai.id)
      new_hire_in = FactoryGirl.create(:employee,
        status: 'active',
        hire_date: Date.new(2016, 7, 29))
      nh_in_profile = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: new_hire_in,
        department_id: Department.find_by(:name => 'Data Analytics & Experimentation').id,
        location_id: mumbai.id)
      new_hire_us = FactoryGirl.create(:employee,
        status: 'active',
        hire_date: Date.new(2016, 7, 29))
      nh_us_profile = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: new_hire_us,
        location_id: sf.id)
      mailer = double(PeopleAndCultureMailer)

      # 7/29/2016 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, '+00:00'))

      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap_entry).to receive(:dn).and_return('the old dn')
      expect(ldap).to receive(:replace_attribute).once.with(
        'the old dn', :userAccountControl, '514'
      )
      expect(ldap).to receive(:rename).once.with({
        :olddn=>'the old dn',
        :newrdn=>"cn=#{leave.cn}",
        :delete_attributes=>true,
        :new_superior=>'ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com'})
      expect(ldap).to receive(:replace_attribute).once.with(
        'the old dn', :userAccountControl, '514'
      )
      expect(ldap).to receive(:rename).once.with({
        :olddn=>'the old dn',
        :newrdn=>"cn=#{contract_end.cn}",
        :delete_attributes=>true,
        :new_superior=>'ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com'})
      expect(ldap).to receive(:replace_attribute).once.with(
        'the old dn', :userAccountControl, '514'
      )
      expect(ldap).to receive(:rename).once.with({
        :olddn=>'the old dn',
        :newrdn=>"cn=#{termination.cn}",
        :delete_attributes=>true,
        :new_superior=>'ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com'})
      expect(ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, '512'
      )
      expect(ldap).to_not receive(:replace_attribute).with(
        new_hire_in.dn, :userAccountControl, '512'
      )

      allow(ldap).to receive(:get_operation_result)

      expect(PeopleAndCultureMailer).to receive(:terminate_contract).with(contract_end).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task['employee:change_status'].invoke

      expect(termination.reload.status).to eq('terminated')
      expect(contract_end.reload.status).to eq('terminated')
      expect(leave.reload.status).to eq('inactive')
    end

    it 'should offboard deactivated employee group at 9pm in IST' do
      ind_term = FactoryGirl.create(:employee,
        status: 'active',
        termination_date: Date.new(2016, 7, 29))
      ind_term_prof = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: ind_term,
        location: mumbai,
        department: Department.find_by(:name => 'Technology/CTO Admin'))

      # 7/29/ 2017 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, '+00:00'))

      ad = double(ActiveDirectoryService)
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:deactivate)
      allow(ad).to receive(:activate)
      allow(ad).to receive(:terminate)

      Rake::Task['employee:change_status'].invoke

      expect(ind_term.reload.status).to eq('terminated')
      expect(ind_term_prof.reload.profile_status).to eq('terminated')
    end

    it 'should send tech table offboard instructions at noon on the termination day in IST' do
      manager = FactoryGirl.create(:regular_employee)

      termination = FactoryGirl.create(:employee,
        status: 'active',
        manager: manager,
        termination_date: Date.new(2016, 7, 29))
      profile = FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: termination,
        location: mumbai,
        department: Department.find_by(:name => 'Technology/CTO Admin'))

        Timecop.freeze(Time.new(2016, 7, 29, 6, 30, 0, '+00:00'))

        expect(TechTableMailer).to receive_message_chain(:offboard_instructions, :deliver_now)
        Rake::Task['employee:change_status'].invoke
    end

    context 'when removing worker from AD memberships' do
      let!(:employee)   { FactoryGirl.create(:employee, termination_date: Date.new(2016, 8, 21)) }
      let(:success)     { OpenStruct.new(code: 0, message: 'msg') }
      let(:ldap_entry)  { Net::LDAP::Entry.new(employee) }

      before do
        FactoryGirl.create(:profile, employee: employee, location: sf)
        # 8/28/2016 at 3am PST/10am UTC
        Timecop.freeze(Time.new(2016, 8, 28, 10, 0, 0, '+00:00'))

        ldap_entry[:memberOf] = ['sec_dn_1', 'sec_dn_2']
        allow(ldap).to receive(:search).and_return([ldap_entry])
        allow(ldap).to receive(:modify)
        allow(ldap).to receive(:get_operation_result).and_return(success)

        Rake::Task['employee:change_status'].invoke
      end

      after do
        Timecop.return
      end

      it 'removes from all security groups at 3am, 7 days after termination' do
        expect(ldap).to have_received(:modify).once
          .with({:dn => 'sec_dn_1', :operations => [[:delete, :member, employee.dn]]})
        expect(ldap).to have_received(:modify).once
          .with({:dn => 'sec_dn_2', :operations => [[:delete, :member, employee.dn]]})
      end
    end
  end

  describe '#employee:send_onboarding_reminders' do
    let!(:worker_type) { FactoryGirl.create(:worker_type, code: 'FTR') }
    let!(:json) { File.read(Rails.root.to_s+'/spec/fixtures/adp_rehire_event.json') }
    let!(:nh_evt) do
      FactoryGirl.create(:adp_event,
        status: 'new',
        json: json,
        kind: 'worker.hire')
    end

    let(:us_due_tom) do
      FactoryGirl.create(:employee,
        status: 'pending',
        request_status: 'completed',
        hire_date: Date.new(2017, 12, 4))
    end

    let!(:us_dt_prof) do
      FactoryGirl.create(:profile,
        start_date: Date.new(2017, 12, 4),
        employee: us_due_tom,
        profile_status: 'pending')
    end

    let(:us_overdue) do
      FactoryGirl.create(:employee,
        status: 'pending',
        request_status: 'waiting',
        hire_date: Date.new(2017, 12, 4))
    end

    let!(:us_od_prof) do
      FactoryGirl.create(:profile,
        employee: us_overdue,
        start_date: Date.new(2017, 12, 4),
        profile_status: 'pending')
    end

    let(:au_due_tom) do
      FactoryGirl.create(:employee,
        status: 'pending',
        request_status: 'waiting',
        hire_date: Date.new(2017, 12, 11))
    end

    let!(:au_profile) do
      FactoryGirl.create(:profile,
        profile_status: 'pending',
        start_date: Date.new(2017, 12, 11),
        employee: au_due_tom,
        location: Location.find_by_name('Melbourne Office'))
    end

    before do
      allow(ReminderWorker).to receive(:perform_async)
    end

    after do
      Timecop.return
    end

    it 'reminds manager to onboard us worker' do
      # 9am PST
      Timecop.freeze(Time.new(2017, 11, 26, 17, 0, 0, '+00:00'))
      Rake::Task['employee:send_onboarding_reminders'].invoke
      expect(ReminderWorker).to have_received(:perform_async).with(employee_id: us_overdue.id)
    end

    it 'reminds manager to onboard au worker' do
      # 9am AEST
      Timecop.freeze(Time.new(2017, 11, 25, 22, 00, 0, '+00:00'))
      Rake::Task['employee:send_onboarding_reminders'].invoke
      expect(ReminderWorker).to have_received(:perform_async).with(employee_id: au_due_tom.id)
    end

    it 'reminds manager to onboard rehire' do
      Timecop.freeze(Time.new(2018, 8, 23, 16, 0, 0, '+00:00'))
      Rake::Task['employee:send_onboarding_reminders'].invoke
     expect(ReminderWorker).to have_received(:perform_async).with({:event_id=>nh_evt. id})
    end
  end

  describe '#employee:send_contract_end_notifications' do
    let!(:manager) { FactoryGirl.create(:employee) }

    let!(:contractor) do
      FactoryGirl.create(:contract_worker,
        status: 'active',
        request_status: 'none',
        contract_end_date: Date.new(2017, 12, 1),
        termination_date: nil,
        manager: manager)
    end

    let!(:cont_2) do
      FactoryGirl.create(:contract_worker,
        status: 'active',
        contract_end_date: Date.new(2017, 11, 11),
        termination_date: Date.new(2017, 12, 1),
        manager: manager)
    end

    before do
      allow(ContractorWorker).to receive(:perform_async)

      Timecop.freeze(Time.new(2017, 11, 17, 17, 0, 0, '+00:00'))
      Rake::Task['employee:send_contract_end_notifications'].invoke
    end

    after do
      Timecop.return
    end

    it 'reminds manager of worker with contract end date in two weeks' do
      expect(ContractorWorker).to have_received(:perform_async).with(contractor.id)
    end

    it 'updates contractor request status' do
      expect(contractor.reload.request_status).to eq('waiting')
    end
  end
end
