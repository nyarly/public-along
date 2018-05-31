require 'rails_helper'
require 'aasm/rspec'

describe Employee, type: :model do
  describe 'validations' do
    let(:employee) do
      FactoryGirl.create(:employee,
        first_name: ' Walter',
        last_name: 'Sobchak ',
        email: 'WSobchak@opentable.com')
    end

    it 'checks presence' do
      expect(employee).to be_valid

      expect(employee).to_not allow_value(nil).for(:first_name)
      expect(employee).to_not allow_value(nil).for(:last_name)
      expect(employee).to_not allow_value(nil).for(:hire_date)
      expect(employee).to     allow_value(nil).for(:email)
    end

    it 'checks strip_whitespace' do
      expect(employee.first_name).to eq('Walter')
      expect(employee.last_name).to eq('Sobchak')
    end

    it 'checks downcase_unique_attrs' do
      expect(employee.email).to eq("wsobchak@opentable.com")
    end
  end

  describe 'state machine' do
    context 'when created' do
      subject { FactoryGirl.create(:employee) }

      it { is_expected.to have_state(:created) }
      it { is_expected.to allow_transition_to(:pending) }
      it { is_expected.to allow_event(:hire) }
      it { is_expected.not_to allow_transition_to(:active) }
      it { is_expected.not_to allow_transition_to(:inactive) }
      it { is_expected.not_to allow_transition_to(:terminated) }
      it { is_expected.not_to allow_event(:rehire_from_event) }
      it { is_expected.not_to allow_event(:activate) }
      it { is_expected.not_to allow_event(:start_leave) }
      it { is_expected.not_to allow_event(:terminate) }
      it { is_expected.not_to allow_event(:terminate_immediately) }
    end

    context 'when pending' do
      subject { FactoryGirl.create(:pending_employee) }

      it { is_expected.to have_state(:pending) }
      it { is_expected.to allow_transition_to(:active) }
      it { is_expected.to allow_event(:activate) }
      it { is_expected.not_to allow_transition_to(:created) }
      it { is_expected.not_to allow_transition_to(:inactive) }
      it { is_expected.not_to allow_transition_to(:terminated) }
      it { is_expected.not_to allow_event(:hire) }
      it { is_expected.not_to allow_event(:rehire_from_event) }
      it { is_expected.not_to allow_event(:start_leave) }
      it { is_expected.not_to allow_event(:terminate) }
      it { is_expected.not_to allow_event(:terminate_immediately) }
    end

    context 'when active' do
      subject { FactoryGirl.create(:active_employee) }

      it { is_expected.to have_state(:active) }
      it { is_expected.to allow_transition_to(:inactive) }
      it { is_expected.to allow_transition_to(:terminated) }
      it { is_expected.to allow_event(:activate) }
      it { is_expected.to allow_event(:start_leave) }
      it { is_expected.to allow_event(:terminate) }
      it { is_expected.to allow_event(:terminate_immediately) }
      it { is_expected.not_to allow_transition_to(:created) }
      it { is_expected.not_to allow_transition_to(:pending) }
      it { is_expected.not_to allow_event(:rehire_from_event) }
    end

    context 'when inactive' do
      subject { FactoryGirl.create(:leave_employee) }

      it { is_expected.to have_state(:inactive) }
      it { is_expected.to allow_transition_to(:active) }
      it { is_expected.to allow_transition_to(:inactive) }
      it { is_expected.to allow_event(:activate) }
      it { is_expected.to allow_event(:start_leave) }
      it { is_expected.not_to allow_transition_to(:created) }
      it { is_expected.not_to allow_transition_to(:pending) }
      it { is_expected.not_to allow_transition_to(:terminated) }
      it { is_expected.not_to allow_event(:hire) }
      it { is_expected.not_to allow_event(:rehire_from_event) }
      it { is_expected.not_to allow_event(:terminate) }
      it { is_expected.not_to allow_event(:terminate_immediately) }
    end

    context 'when terminated' do
      subject { FactoryGirl.create(:terminated_employee) }

      it { is_expected.to have_state(:terminated) }
      it { is_expected.to allow_transition_to(:pending) }
      it { is_expected.to allow_event(:hire) }
      it { is_expected.to allow_event(:rehire_from_event) }
      it { is_expected.not_to allow_transition_to(:created) }
      it { is_expected.not_to allow_transition_to(:active) }
      it { is_expected.not_to allow_transition_to(:inactive) }
      it { is_expected.not_to allow_transition_to(:terminated) }
      it { is_expected.not_to allow_event(:activate) }
      it { is_expected.not_to allow_event(:start_leave) }
      it { is_expected.not_to allow_event(:terminate) }
      it { is_expected.not_to allow_event(:terminate_immediately) }
    end
  end

  describe '#hire!' do
    let(:worker) { FactoryGirl.create(:employee, status: 'created') }

    before do
      FactoryGirl.create(:profile, employee: worker)

      worker.hire!
    end

    it 'updates status' do
      expect(worker.status).to eq('pending')
    end

    it 'has correct profile status' do
      expect(worker.current_profile.profile_status).to eq('pending')
    end
  end

  describe '#rehire_from_event!' do
    let(:ad)       { double(ActiveDirectoryService) }
    let(:worker)  { FactoryGirl.create(:employee, status: 'terminated') }

    before do
      FactoryGirl.create(:profile, employee: worker, profile_status: 'terminated', primary: false)
      FactoryGirl.create(:profile, employee: worker, profile_status: 'pending')
    end

    before do
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:update)

      worker.rehire_from_event!
    end

    it 'updates active directory' do
      expect(ad).to have_received(:update).with([worker])
    end

    it 'updates worker status' do
      expect(worker.status).to eq('pending')
    end
  end

  describe '#activate!' do
    let(:ad) { double(ActiveDirectoryService) }

    before do
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:activate)
    end

    context 'when onboarding complete' do
      let(:worker) do
        FactoryGirl.create(:employee,
          status: 'pending',
          request_status: 'completed')
      end

      before do
        FactoryGirl.create(:profile,
          profile_status: 'pending',
          employee: worker)

        worker.activate!
      end

      it 'updates status to active' do
        expect(worker.status).to eq('active')
      end

      it 'has an active profile' do
        expect(worker.profiles.active.count).to eq(1)
      end

      it 'clears request status' do
        expect(worker.request_status).to eq('none')
      end

      it 'activates AD account' do
        expect(ad).to have_received(:activate).with([worker])
      end
    end

    context 'when onboarding not complete' do
      let(:worker) do
        FactoryGirl.create(:employee,
          status: 'pending',
          request_status: 'waiting')
      end

      before do
        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'pending')

        worker.activate!
      end

      it 'does not update status' do
        expect(worker.status).to eq('pending')
      end

      it 'has a pending profile' do
        expect(worker.profiles.pending.count).to eq(1)
      end

      it 'does not change request status' do
        expect(worker.request_status).to eq('waiting')
      end

      it 'does not activate AD account' do
        expect(ad).not_to have_received(:activate)
      end
    end

    context 'when rehire' do
      let(:worker) do
        FactoryGirl.create(:employee,
          status: 'pending',
          request_status: 'completed')
      end

      before do
        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'terminated',
          primary: false)

        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'pending')

        worker.activate!
      end

      it 'updates status' do
        expect(worker.status).to eq('active')
      end

      it 'has an active profile' do
        expect(worker.profiles.active.count).to eq(1)
      end

      it 'has a terminated profile' do
        expect(worker.profiles.terminated.count).to eq(1)
      end

      it 'has an active profile in the primary position' do
        expect(worker.current_profile.profile_status).to eq('active')
        expect(worker.current_profile.primary).to eq(true)
      end

      it 'clears the request status' do
        expect(worker.request_status).to eq('none')
      end

      it 'activates AD account' do
        expect(ad).to have_received(:activate).with([worker])
      end
    end

    context 'when returning from leave' do
      let(:worker) { FactoryGirl.create(:employee, status: 'inactive') }

      before do
        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'leave')

        worker.activate!
      end

      it 'updates status' do
        expect(worker.status).to eq('active')
      end

      it 'has an active profile' do
        expect(worker.profiles.active.count).to eq(1)
      end

      it 'does not have a profile on leave' do
        expect(worker.profiles.leave.count).to eq(0)
      end

      it 'has a current profile' do
        expect(worker.current_profile.present?).to be(true)
      end

      it 'activates AD account' do
        expect(ad).to have_received(:activate).with([worker])
      end
    end
  end

  describe '#start_leave!' do
    let(:ad)      { double(ActiveDirectoryService) }
    let(:worker)  { FactoryGirl.create(:employee, status: 'active') }

    before do
      FactoryGirl.create(:profile,
        employee: worker,
        profile_status: 'active')

      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:deactivate)

      worker.start_leave!
    end

    it 'updates status' do
      expect(worker.status).to eq('inactive')
    end

    it 'has a leave profile' do
      expect(worker.profiles.last.profile_status).to eq('leave')
    end

    it 'deactivates AD account' do
      expect(ad).to have_received(:deactivate).with([worker])
    end
  end

  describe '#terminate!' do
    let(:service) { instance_double(EmployeeService::Offboard) }

    before do
      allow(EmployeeService::Offboard).to receive(:new).and_return(service)
      allow(service).to receive(:execute_termination)
    end

    context 'with termination date' do
      let(:worker) do
        FactoryGirl.create(:employee,
          status: 'active',
          request_status: 'completed',
          termination_date: Date.today)
      end

      before do
        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'active')


        worker.terminate!
      end

      it 'updates status' do
        expect(worker.status).to eq('terminated')
      end

      it 'updates profile status' do
        expect(worker.profiles.terminated.count).to eq(1)
      end

      it 'clears request queue' do
        expect(worker.request_status).to eq('none')
      end

      it 'runs the offboard service' do
        expect(EmployeeService::Offboard).to have_received(:new).with(worker)
        expect(service).to have_received(:execute_termination)
      end
    end

    context 'when contractor without termination date' do
      let(:worker) do
        FactoryGirl.create(:employee,
          status: 'active',
          request_status: 'none',
          contract_end_date: Date.today)
      end

      before do
        FactoryGirl.create(:profile,
          profile_status: 'active',
          employee: worker)

        worker.terminate!
      end

      it 'updates status' do
        expect(worker.status).to eq('terminated')
      end

      it 'updates profile status' do
        expect(worker.profiles.terminated.count).to eq(1)
      end

      it 'ignores request queue' do
        expect(worker.request_status).to eq('none')
      end

      it 'runs the offboard service' do
        expect(EmployeeService::Offboard).to have_received(:new).with(worker)
        expect(service).to have_received(:execute_termination)
      end
    end
  end

  describe '#terminate_immediately!' do
    let(:ad)      { double(ActiveDirectoryService) }
    let(:service) { double(EmployeeService::Offboard) }
    let(:mailer)  { double(TechTableMailer) }

    let(:worker) do
      FactoryGirl.create(:employee,
        status: 'active',
        request_status: 'none',
        termination_date: Date.yesterday)
    end

    before do
      FactoryGirl.create(:profile,
        employee: worker,
        profile_status: 'active')

      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:update)
      allow(EmployeeService::Offboard).to receive(:new).and_return(service)
      allow(service).to receive(:execute_termination)
      allow(TechTableMailer).to receive(:offboard_instructions).and_return(mailer)
      allow(mailer).to receive(:deliver_now)

      worker.terminate_immediately!
    end

    it 'updates active directory' do
      expect(ActiveDirectoryService).to have_received(:new)
      expect(ad).to have_received(:update).with([worker])
    end

    it 'sends TechTable offboard instructions' do
      expect(TechTableMailer).to have_received(:offboard_instructions).with(worker)
      expect(mailer).to have_received(:deliver_now)
    end

    it 'runs the offboarding service' do
      expect(EmployeeService::Offboard).to have_received(:new).with(worker)
      expect(service).to have_received(:execute_termination)
    end

    it 'has the correct status' do
      expect(worker.status).to eq('terminated')
    end

    it 'has the correct profile status' do
      expect(worker.current_profile.profile_status).to eq('terminated')
    end
  end

  describe '#current_profile=' do
    let(:worker_type)   { FactoryGirl.create(:worker_type) }
    let(:department)    { FactoryGirl.create(:department) }
    let(:location)      { FactoryGirl.create(:location) }
    let(:job_title)     { FactoryGirl.create(:job_title) }
    let(:business_unit) { FactoryGirl.create(:business_unit) }

    let(:profile_attrs) do
      {
        start_date: 1.week.from_now,
        business_title: 'new biz title',
        manager_adp_employee_id: '112233',
        department_id: department.id,
        location_id: location.id,
        worker_type_id: worker_type.id,
        job_title_id: job_title.id,
        adp_assoc_oid: 'xxii',
        adp_employee_id: '332211',
        business_unit: business_unit
      }
    end

    context 'when first profile created' do
      let(:employee) { FactoryGirl.create(:employee) }

      before do
        employee.build_current_profile(profile_attrs)
        employee.save
      end

      it 'creates a new current profile via attributes when there is none' do
        expect(employee.current_profile.adp_employee_id).to eq('332211')
      end
    end

    context 'when worker has current profile' do
      let(:employee) { FactoryGirl.create(:employee) }
      let!(:profile) { FactoryGirl.create(:profile, employee: employee) }

      before do
        employee.build_current_profile(profile_attrs)
        employee.save
      end

      it 'creates new profile as current profile' do
        expect(employee.current_profile.business_title).to eq('new biz title')
        expect(employee.current_profile.primary).to eq(true)
        expect(employee.reload.profiles.count).to eq(2)
      end

      it 'makes the old profile not current profile' do
        expect(profile.reload.primary).to eq(false)
      end
    end

    context 'when assigning current profile from existing profiles' do
      let(:employee) { FactoryGirl.create(:employee) }
      let!(:profile) do
        FactoryGirl.create(:profile,
          employee: employee,
          primary: false)
      end

      before do
        employee.current_profile = profile
        employee.current_profile.save!
        employee.save!
      end

      it 'gives the employee one current profile' do
        expect(employee.current_profile).to eq(profile)
      end

      it 'updates the profile primary flag' do
        expect(profile.reload.primary).to eq(true)
      end
    end

    context 'when current profile switches' do
      let(:employee)   { FactoryGirl.create(:employee) }
      let!(:profile)   { FactoryGirl.create(:profile, adp_employee_id: 'a', employee: employee) }
      let!(:profile_2) { FactoryGirl.create(:profile, adp_employee_id: 'b', employee: employee, primary: false) }

      before do
        employee.current_profile = profile_2
        employee.current_profile.save
        employee.save
      end

      it 'has the new profile as current profile' do
        expect(employee.reload.current_profile).to eq(profile_2)
        expect(employee.reload.current_profile.primary).to eq(true)
        expect(employee.current_profile.primary).to eq(true)
        expect(employee.current_profile.adp_employee_id).to eq('b')
        expect(employee.current_profile).to eq(profile_2)
      end

      it 'old profile is not primary' do
        expect(profile.reload.primary).to eq(false)
        expect(profile_2.reload.primary).to eq(true)
        expect(employee.reload.profiles.first.primary).to eq(false)
      end
    end
  end

  describe '#build_current_profile' do
    let(:worker_type) { FactoryGirl.create(:worker_type) }
    let(:department)  { FactoryGirl.create(:department) }
    let(:location)    { FactoryGirl.create(:location) }
    let(:job_title)   { FactoryGirl.create(:job_title) }

    let(:profile_attrs) do
      {
        start_date: 1.week.from_now,
        business_title: 'new biz title',
        manager_adp_employee_id: '112233',
        department_id: department.id,
        location_id: location.id,
        worker_type_id: worker_type.id,
        job_title_id: job_title.id,
        adp_assoc_oid: 'xxii',
        adp_employee_id: '332211'
      }
    end

    let(:employee) { build(:employee) }

    before do
      employee.build_current_profile(profile_attrs)
    end

    it 'has a current profile' do
      expect(employee.current_profile.worker_type).to eq(worker_type)
    end
  end

  describe '#leave_return_group' do
    it "should scope the correct leave return group" do
      activation_group = [
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.yesterday),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.today),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.tomorrow)
      ]
      non_activation_group = [
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 1.week.ago),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 2.days.ago),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 2.days.from_now),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 1.week.from_now)
      ]

      expect(Employee.leave_return_group).to match_array(activation_group)
      expect(Employee.leave_return_group).to_not include(non_activation_group)
    end
  end

  describe '#deactivation_group' do
    it "should scope the correct deactivation group" do
      deactivation_group = [
        FactoryGirl.create(:employee, :contract_end_date => Date.yesterday),
        FactoryGirl.create(:employee, :contract_end_date => Date.today),
        FactoryGirl.create(:employee, :contract_end_date => Date.tomorrow),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => Date.yesterday),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => Date.today),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => Date.tomorrow)
      ]
      non_deactivation_group = [
        FactoryGirl.create(:employee, :contract_end_date => 1.week.ago),
        FactoryGirl.create(:employee, :contract_end_date => 2.days.ago),
        FactoryGirl.create(:employee, :contract_end_date => 2.days.from_now),
        FactoryGirl.create(:employee, :contract_end_date => 1.week.from_now),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 1.week.ago),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 2.days.ago),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 2.days.from_now),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 1.week.from_now)
      ]

      expect(Employee.deactivation_group).to match_array(deactivation_group)
      expect(Employee.deactivation_group).to_not include(non_deactivation_group)
    end
  end

  describe '#active_security_profiles' do
    it "should find active/revoked security profiles" do
      emp = FactoryGirl.create(:regular_employee)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      user = FactoryGirl.create(:user)
      emp_transaction = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: emp.id)
      revoking_transaction = FactoryGirl.create(:emp_transaction,
        employee_id: emp.id,
        user_id: user.id,
        kind: 'security_access')
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        security_profile_id: sec_prof_1.id,
        emp_transaction_id: emp_transaction.id,
        revoking_transaction_id: revoking_transaction.id)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile,
        security_profile_id: sec_prof_2.id,
        emp_transaction_id: emp_transaction.id,
        revoking_transaction_id: nil)

      expect(emp.active_security_profiles).to include(sec_prof_2)
      expect(emp.revoked_security_profiles).to include(sec_prof_1)
    end

    it "should group security profiles that do not belong to current department" do
      department = FactoryGirl.create(:department)
      employee = FactoryGirl.create(:employee)
      profile = FactoryGirl.create(:profile,
        employee: employee,
        department: department)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      emp_trans = FactoryGirl.create(:emp_transaction, employee_id: employee.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof_1.id,
        revoking_transaction_id: nil)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof_2.id,
        revoking_transaction_id: nil)
      dept_sec_prof_1 = FactoryGirl.create(:dept_sec_prof,
        department_id: department.id,
        security_profile_id: sec_prof_1.id)

      expect(employee.security_profiles_to_revoke).to include(sec_prof_2)
      expect(employee.security_profiles_to_revoke).to_not include(sec_prof_1)
    end
  end

  describe '#onboarding_due_date' do
    let(:worker) do
      FactoryGirl.create(:employee, hire_date: Date.new(2016, 7, 25))
    end

    context 'when US worker' do
      before do
        FactoryGirl.create(:profile,
          employee: worker,
          start_date: Date.new(2016, 7, 25))
      end

      it 'is 5 days before start date' do
        expect(worker.onboarding_due_date).to eq(Time.new(2016, 7, 18, 9, 0, 0, '+00:00'))
      end
    end

    context 'when rehire' do
      before do
        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'pending',
          start_date: Date.new(2017, 9, 25))

        FactoryGirl.create(:profile,
          employee: worker,
          profile_status: 'terminated',
          start_date: Date.new(2016, 7, 18))
      end

      it 'is for new position' do
        expect(worker.onboarding_due_date).to eq(Time.new(2017, 9, 18, 9, 0, 0, '+00:00'))
      end
    end

    context 'when UK worker' do
      before do
        FactoryGirl.create(:profile,
          employee: worker,
          start_date: Date.new(2016, 7, 25),
          location: Location.find_by(name: 'London Office'))
      end

      it 'is 5 days before start date' do
        expect(worker.onboarding_due_date).to eq(Time.new(2016, 7, 18, 9, 0, 0, '+00:00'))
      end
    end

    context 'when not in US or UK' do
      before do
        FactoryGirl.create(:profile,
          employee: worker,
          start_date: Date.new(2016, 7, 25),
          location: Location.find_by(name: 'Mumbai Office'))
      end

      it 'is 10 days before start date' do
        expect(worker.onboarding_due_date).to eq(Time.new(2016, 7, 11, 9, 0, 0, '+00:00'))
      end
    end
  end

  describe '#offboarding_cutoff' do
    it "should calculate the offboarding submission cutoff" do
      past_due_emp = FactoryGirl.create(:employee,
        termination_date: Date.new(2016, 7, 25, 2))
      prof_1 = FactoryGirl.create(:profile,
        employee: past_due_emp,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("San Francisco Headquarters"))

      expect(past_due_emp.offboarding_cutoff).to eq(DateTime.new(2016, 7, 25, 19))
    end
  end

  describe '#nearest_time_zone' do
    context 'when worker in SF office' do
      let(:worker) { FactoryGirl.create(:employee) }

      before do
        FactoryGirl.create(:profile,
          employee: worker,
          location: Location.find_by(name: 'San Francisco Headquarters'))
      end

      it 'is set correctly' do
        expect(worker.nearest_time_zone).to eq('America/Los_Angeles')
      end
    end
  end

  describe "#email_options" do
    it "should return EMAIL_OPTIONS with offboarding option" do
      employee = FactoryGirl.create(:employee, termination_date: Date.new(2018, 3, 6))
      expect(employee.email_options).to eq(Employee::EMAIL_OPTIONS)
    end

    it "should return EMAIL_OPTIONS without offboarding option" do
      employee = FactoryGirl.create(:employee, termination_date: nil)
      expect(employee.email_options).to_not include("Offboarding")
    end
  end

  describe "#onboarding_reminder_group" do
    let!(:due_tomorrow_no_onboard) do
      FactoryGirl.create(:employee,
        status: 'pending',
        last_name: "Aaaa",
        hire_date: Date.new(2017, 5, 8),
        request_status: "waiting")
    end

    let!(:due_tomorrow_no_onboard_profile) do
      FactoryGirl.create(:profile,
        start_date: Date.new(2017, 5, 8),
        employee: due_tomorrow_no_onboard)
    end

    let!(:due_tomorrow_no_onboard_au) do
      FactoryGirl.create(:employee,
        status: 'pending',
        last_name: "Bbbb",
        hire_date: Date.new(2017, 5, 15),
        request_status: "waiting")
    end

    let!(:due_tomorrow_no_onboard_au_profile) do
      FactoryGirl.create(:profile,
        employee: due_tomorrow_no_onboard_au,
        start_date: Date.new(2017, 5, 15),
        location: Location.find_by_name("Melbourne Office"))
    end

    let!(:due_tomorrow_w_onboard) do
      FactoryGirl.create(:employee,
        status: 'pending',
        last_name: "CCC",
        request_status: "completed",
        hire_date: Date.new(2017, 5, 8))
    end

    let!(:due_tomorrow_w_onboard_profile) do
      FactoryGirl.create(:profile,
        start_date: Date.new(2017, 5, 8),
        employee: due_tomorrow_w_onboard)
    end

    let!(:emp_transaction) do
      FactoryGirl.create(:emp_transaction,
        kind: "onboarding",
        employee: due_tomorrow_w_onboard)
    end

    let!(:onboard) do
      FactoryGirl.create(:onboarding_info,
        emp_transaction: emp_transaction)
    end

    let!(:due_later_no_onboard) do
      FactoryGirl.create(:employee,
        last_name: "DDD",
        request_status: "waiting",
        hire_date: Date.new(2017, 9, 1))
    end

    let!(:due_later_profile) do
      FactoryGirl.create(:profile,
        start_date: Date.new(2017, 9, 1),
        employee: due_later_no_onboard)
    end

    before do
      Timecop.freeze(Time.new(2017, 4, 29, 16, 00, 0, "+00:00"))
    end

    after do
      Timecop.return
    end

    it "should return the right employees" do
      expect(Employee.onboarding_reminder_group)
        .to eq([due_tomorrow_no_onboard, due_tomorrow_no_onboard_au])
    end
  end

  describe '#ad_attrs' do

    context "regular worker" do
      let(:employee) do
        FactoryGirl.create(:employee, :with_manager,
          status: 'active',
          first_name: "Bob",
          last_name: "Barker")
      end

      before do
        FactoryGirl.create(:profile, :with_valid_ou, profile_status: 'active', employee: employee)
      end

      it "should create a cn" do
        expect(employee.cn).to eq("Bob Barker")
      end

      it "should create an fn" do
        expect(employee.fn).to eq("Barker, Bob")
      end

      it "should find the correct ou" do
        expect(employee.ou).to eq("ou=Operations,ou=EU,ou=Users,")
      end

      it "should create a dn" do
        expect(employee.dn).to eq("cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      end

      it "should set the correct account expiry" do
        expect(employee.generated_account_expires).to eq("9223372036854775807")
      end

      it "should set the correct address" do
        expect(employee.address).to be_nil
      end

      it "should create attr hash" do
        expect(employee.ad_attrs).to eq(
          {
            cn: "Bob Barker",
            dn: "cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
            objectclass: ["top", "person", "organizationalPerson", "user"],
            givenName: "Bob",
            sn: "Barker",
            sAMAccountName: employee.sam_account_name,
            displayName: employee.cn,
            userPrincipalName: employee.generated_upn,
            manager: employee.manager.dn,
            mail: employee.email,
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: employee.location.country,
            accountExpires: employee.generated_account_expires,
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: employee.worker_type.name,
            physicalDeliveryOfficeName: employee.location.name,
            department: employee.department.name,
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone,
            streetAddress: nil,
            l: nil,
            st: nil,
            postalCode: nil,
            # thumbnailPhoto: Base64.decode64(employee.image_code)
            # TODO comment back in when we bring back thumbnail photo
          }
        )
      end
    end

    context "regular worker that has been assigned a sAMAccountName" do
      let(:employee) { FactoryGirl.create(:employee, :with_manager,
                       first_name: "Mary",
                       last_name: "Sue",
                       sam_account_name: "msue",
                       email: nil) }
      let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                       employee: employee) }

      it "should generate an email using the sAMAccountName" do
        expect(employee.generated_email).to eq("msue@opentable.com")
      end

      it "should create attr hash" do
        expect(employee.ad_attrs).to eq(
          {
            cn: "Mary Sue",
            dn: "cn=Mary Sue,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
            objectclass: ["top", "person", "organizationalPerson", "user"],
            givenName: "Mary",
            sn: "Sue",
            sAMAccountName: "msue",
            displayName: employee.cn,
            userPrincipalName: employee.generated_upn,
            manager: employee.manager.dn,
            mail: "msue@opentable.com",
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: employee.location.country,
            accountExpires: employee.generated_account_expires,
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: employee.worker_type.name,
            physicalDeliveryOfficeName: employee.location.name,
            department: employee.department.name,
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone,
            streetAddress: nil,
            l: nil,
            st: nil,
            postalCode: nil,
            # thumbnailPhoto: Base64.decode64(employee.image_code)
            # TODO comment back in when we bring back thumbnail photo
          }
        )
      end
    end

    context "with a contingent worker" do
      let(:employee) { FactoryGirl.create(:employee, :with_manager,
                       first_name: "Sally",
                       last_name: "Field",
                       sam_account_name: "sfield",
                       contract_end_date: 1.month.from_now) }

      let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                       employee: employee) }

      it "should set the correct account expiry" do
        date = employee.contract_end_date + 1.day
        time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
        expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
      end

      it "should set the correct address" do
        expect(employee.address).to be_nil
      end

      it "should create attr hash" do
        expect(employee.ad_attrs).to eq(
          {
            cn: "Sally Field",
            dn: "cn=Sally Field,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
            objectclass: ["top", "person", "organizationalPerson", "user"],
            givenName: "Sally",
            sn: "Field",
            sAMAccountName: employee.sam_account_name,
            displayName: employee.cn,
            userPrincipalName: employee.generated_upn,
            manager: employee.manager.dn,
            mail: employee.email,
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: employee.location.country,
            accountExpires: employee.generated_account_expires,
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: employee.worker_type.name,
            physicalDeliveryOfficeName: employee.location.name,
            department: employee.department.name,
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone,
            streetAddress: nil,
            l: nil,
            st: nil,
            postalCode: nil,
            # thumbnailPhoto: Base64.decode64(employee.image_code)
            # TODO comment back in when we bring back thumbnail photo
          }
        )
      end
    end

    context "with a contingent worker that has been terminated" do
      let(:cont_wt)  { FactoryGirl.create(:worker_type, :contractor) }
      let(:employee) { FactoryGirl.create(:employee, :with_manager,
                       status: 'terminated',
                       first_name: "Bob",
                       last_name: "Barker",
                       contract_end_date: 1.month.from_now.end_of_day,
                       termination_date: 1.day.from_now.end_of_day) }

      let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                       profile_status: 'terminated',
                       worker_type: cont_wt,
                       employee: employee) }

      it "should set the correct account expiry" do
        date = employee.termination_date + 1.day
        time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
        expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
      end

      it "should create attr hash" do
        expect(employee.ad_attrs).to eq(
          {
            cn: "Bob Barker",
            dn: "cn=Bob Barker,ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com",
            objectclass: ["top", "person", "organizationalPerson", "user"],
            givenName: "Bob",
            sn: "Barker",
            sAMAccountName: employee.sam_account_name,
            displayName: employee.cn,
            userPrincipalName: employee.generated_upn,
            manager: employee.manager.dn,
            mail: employee.email,
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: employee.location.country,
            accountExpires: employee.generated_account_expires,
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: employee.worker_type.name,
            physicalDeliveryOfficeName: employee.location.name,
            department: employee.department.name,
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone,
            streetAddress: nil,
            l: nil,
            st: nil,
            postalCode: nil,
            # thumbnailPhoto: Base64.decode64(employee.image_code)
            # TODO comment back in when we bring back thumbnail photo
          }
        )
      end
    end


    context 'with a remote worker and one address line' do
      let(:employee) { FactoryGirl.create(:employee, :with_manager,
                       first_name: 'Bob',
                       last_name: 'Barker') }
      let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou, :remote,
                       employee: employee) }
      let!(:address) { FactoryGirl.create(:address,
                       line_1: '123 Fake St.',
                       line_2: nil,
                       city: 'Beverly Hills',
                       state_territory: 'CA',
                       postal_code: '90210',
                       addressable_type: 'Employee',
                       addressable_id: employee.id) }

      it 'should set the correct address' do
        expect(employee.address.complete_street).to eq('123 Fake St.')
      end

      it 'should create attr hash' do
        expect(employee.ad_attrs).to eq(
          {
            cn: 'Bob Barker',
            dn: 'cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
            objectclass: ['top', 'person', 'organizationalPerson', 'user'],
            givenName: 'Bob',
            sn: 'Barker',
            sAMAccountName: employee.sam_account_name,
            displayName: employee.cn,
            userPrincipalName: employee.generated_upn,
            manager: employee.manager.dn,
            mail: employee.email,
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: employee.location.country,
            accountExpires: employee.generated_account_expires,
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: employee.worker_type.name,
            physicalDeliveryOfficeName: employee.location.name,
            department: employee.department.name,
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone,
            streetAddress: '123 Fake St.',
            l: 'Beverly Hills',
            st: 'CA',
            postalCode: '90210',
            # thumbnailPhoto: Base64.decode64(employee.image_code)
            # TODO comment back in when we bring back thumbnail photo
          }
        )
      end
    end

    context 'with a remote worker and two address lines' do
      let(:remote_loc)  { FactoryGirl.create(:location, :remote) }
      let(:employee)    { FactoryGirl.create(:employee, :with_manager,
                          first_name: 'Bob',
                          last_name: 'Barker') }
      let!(:profile)    { FactoryGirl.create(:profile,
                          employee: employee,
                          location: remote_loc,
                          department: Department.find_by_name('Customer Support')) }
      let!(:address) { FactoryGirl.create(:address,
                       line_1: '123 Fake St.',
                       line_2: 'Apt 3G',
                       city: 'Beverly Hills',
                       state_territory: 'CA',
                       postal_code: '90210',
                       addressable_type: 'Employee',
                       addressable_id: employee.id) }

      it 'should set the correct address' do
        expect(employee.address.complete_street).to eq('123 Fake St., Apt 3G')
      end

      it 'should create attr hash' do
        expect(employee.ad_attrs).to eq(
          {
            cn: 'Bob Barker',
            dn: 'cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
            objectclass: ['top', 'person', 'organizationalPerson', 'user'],
            givenName: 'Bob',
            sn: 'Barker',
            sAMAccountName: employee.sam_account_name,
            displayName: employee.cn,
            userPrincipalName: employee.generated_upn,
            manager: employee.manager.dn,
            mail: employee.email,
            unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
            co: employee.location.country,
            accountExpires: employee.generated_account_expires,
            title: employee.job_title.name,
            description: employee.job_title.name,
            employeeType: employee.worker_type.name,
            physicalDeliveryOfficeName: employee.location.name,
            department: employee.department.name,
            employeeID: employee.employee_id,
            telephoneNumber: employee.office_phone,
            streetAddress: '123 Fake St., Apt 3G',
            l: 'Beverly Hills',
            st: 'CA',
            postalCode: '90210',
            # thumbnailPhoto: Base64.decode64(employee.image_code)
            # TODO comment back in when we bring back thumbnail photo
          }
        )
      end
    end

    context "with a terminated worker" do
      let(:employee) { FactoryGirl.create(:employee,
                       termination_date: 2.days.from_now) }
      let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                       employee: employee) }

      it "should set the correct account expiry" do
        date = employee.termination_date + 1.day
        time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
        expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
      end
    end

    context "when it does not find a location and department ou match" do
      let!(:employee) { FactoryGirl.create(:regular_employee) }

      it "should assign the user to the provisional ou" do
        expect(employee.ou).to eq("ou=Provisional,ou=Users,")
      end
    end
  end

  describe "#last_changed_at" do
    let(:yesterday)                 { 1.day.ago }
    let(:two_days_ago)              { 2.days.ago }
    let(:last_week)                 { 1.week.ago }
    let(:last_changed_at_onboard)   { FactoryGirl.create(:employee,
                                      created_at: last_week) }
    let(:onboard)                   { FactoryGirl.create(:emp_transaction,
                                      employee: last_changed_at_onboard,
                                      created_at: two_days_ago) }
    let!(:onboard_info)             { FactoryGirl.create(:onboarding_info,
                                      emp_transaction: onboard,
                                      created_at: two_days_ago) }
    let(:last_changed_at_emp_delta) { FactoryGirl.create(:employee,
                                      created_at: last_week) }
    let(:onboard_2)                 { FactoryGirl.create(:emp_transaction,
                                      employee: last_changed_at_emp_delta,
                                      created_at: two_days_ago) }
    let!(:onboard_info_2)           { FactoryGirl.create(:onboarding_info,
                                      emp_transaction: onboard_2,
                                      created_at: two_days_ago) }
    let!(:emp_delta)                { FactoryGirl.create(:emp_delta,
                                      employee: last_changed_at_emp_delta,
                                      before: {"thing"=>"thing"},
                                      after: {"thing"=>"thing"},
                                      created_at: yesterday) }
    let(:last_changed_at_offboard)  { FactoryGirl.create(:employee) }
    let(:offboard)                  { FactoryGirl.create(:emp_transaction,
                                      employee: last_changed_at_offboard,
                                      created_at: two_days_ago) }
    let!(:offboard_info)            { FactoryGirl.create(:offboarding_info,
                                      emp_transaction: offboard,
                                      created_at: two_days_ago) }
    let(:last_changed_at_create)    { FactoryGirl.create(:employee,
                                      created_at: last_week) }

    it "should get the right date last changed" do
      expect(last_changed_at_onboard.last_changed_at).to eq(two_days_ago)
      expect(last_changed_at_emp_delta.last_changed_at).to eq(yesterday)
      expect(last_changed_at_offboard.last_changed_at).to eq(two_days_ago)
      expect(last_changed_at_create.last_changed_at).to eq(last_week)
    end
  end
end
