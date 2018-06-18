require 'rails_helper'

RSpec.describe EmployeeProfile do
  let(:parser)        { AdpService::WorkerJsonParser.new }
  let!(:worker_type)  { FactoryGirl.create(:worker_type, code: 'FTR') }
  let!(:department)   { FactoryGirl.create(:department, code: '125000') }
  let(:location)      { Location.find_by(code: 'LOS') }
  let(:job_title)     { FactoryGirl.create(:job_title, code: 'SADEN') }
  let(:business_unit) { FactoryGirl.create(:business_unit, code: 'OTUS') }
  let!(:top_manager) { FactoryGirl.create(:active_employee) }
  let!(:manager) { FactoryGirl.create(:active_employee, manager: top_manager, parent_id: top_manager.id) }

  before do
    FactoryGirl.create(:active_profile, employee: manager, adp_employee_id: '654321')
  end

  describe '#link_accounts' do
    context 'when rehiring terminated worker' do
      let(:rehire_json) { File.read(Rails.root.to_s + '/spec/fixtures/adp_rehire_event.json') }
      let(:terminated)  { FactoryGirl.create(:employee, status: 'terminated') }
      let(:event)       { FactoryGirl.create(:adp_event, json: rehire_json, status: 'new') }

      before do
        FactoryGirl.create(:profile, employee: terminated, profile_status: 'terminated')
        described_class.new.link_accounts(terminated.id, event.id)
      end

      it 'creates a new employee profile on terminated employee' do
        expect(terminated.profiles.count).to eq(2)
      end

      it 'has a pending profile' do
        expect(terminated.profiles.pending.count).to eq(1)
      end

      it 'has a terminated profile' do
        expect(terminated.profiles.terminated.count).to eq(1)
      end

      it 'assigns the new role as the current profile' do
        expect(terminated.current_profile.profile_status).to eq('pending')
        expect(terminated.current_profile.primary).to be(true)
      end

      it 'clears the termination date' do
        expect(terminated.termination_date).to eq(nil)
      end
    end

    context 'when onboarding conversion' do
      let(:hire_event) { File.read(Rails.root.to_s + '/spec/fixtures/adp_hire_event.json') }
      let(:event)      { FactoryGirl.create(:adp_event, json: hire_event, status: 'new') }
      let(:cont)       { FactoryGirl.create(:worker_type, kind: 'Contractor') }
      let(:contractor) do
        FactoryGirl.create(:employee,
          status: 'active',
          contract_end_date: 1.week.from_now.end_of_day,
          hire_date: Date.new(2018, 1, 1))
      end

      before do
        FactoryGirl.create(:worker_type, code: 'OLFR', kind: 'Regular')
        FactoryGirl.create(:profile, employee: contractor, profile_status: 'active', worker_type: cont)
        described_class.new.link_accounts(contractor.id, event.id)
      end

      it 'creates a new employee profile' do
        expect(contractor.reload.profiles.count).to eq(2)
      end

      it 'has a pending profile' do
        expect(contractor.reload.profiles.pending.count).to eq(1)
      end

      it 'has an active profile' do
        expect(contractor.reload.profiles.active.count).to eq(1)
      end

      it 'retains the active profile as the current profile' do
        expect(contractor.reload.current_profile.profile_status).to eq('active')
        expect(contractor.reload.current_profile.primary).to be(true)
      end

      it 'clears the contract end date' do
        expect(contractor.reload.contract_end_date).to eq(nil)
      end

      it 'does not change the hire date' do
        expect(contractor.hire_date).to eq(Date.new(2018, 1, 1))
      end
    end
  end

  describe '#update_employee' do
    let(:json) { JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/adp_worker.json')) }

    let(:employee) do
      FactoryGirl.create(:employee,
        status: 'active',
        adp_status: 'Active',
        legal_first_name: 'Jane',
        first_name: 'Jane',
        last_name: 'Goodall',
        hire_date: Date.new(2014, 6, 1),
        contract_end_date: nil,
        office_phone: nil,
        personal_mobile_phone: '(888) 888-8888',
        business_card_title: job_title.name,
        manager: manager,
        payroll_file_number: '123456')
    end

    let!(:profile) do
      FactoryGirl.create(:active_profile,
        employee: employee,
        adp_assoc_oid: 'AAABBBCCCDDD',
        adp_employee_id: '123456',
        department: department,
        job_title: job_title,
        location: location,
        start_date: Date.new(2017, 1, 1),
        worker_type: worker_type,
        management_position: false,
        manager_adp_employee_id: '654321',
        business_unit: business_unit)
    end

    context 'when employee has no changes' do
      before do
        w_hash = parser.gen_worker_hash(json['workers'][0])

        described_class.new.update_employee(employee, w_hash)
      end

      it 'does not create an emp delta' do
        expect(employee.emp_deltas.count).to eq(0)
      end

      it 'does not create a new profile' do
        expect(employee.profiles.count).to eq(1)
      end

      it 'does not update information' do
        expect(employee.current_profile).to eq(profile)
      end
    end

    context 'when employee info is updated' do
      before do
        employee.last_name = 'Good All'
        employee.save
        w_hash = parser.gen_worker_hash(json['workers'][0])

        described_class.new.update_employee(employee, w_hash)
      end

      it 'updates the info' do
        expect(employee.reload.last_name).to eq('Goodall')
      end

      it 'creates an emp delta with the change' do
        expect(employee.emp_deltas.last.after).to eq('last_name' => 'Goodall')
        expect(employee.emp_deltas.last.before).to eq('last_name' => 'Good All')
      end

      it 'does not create a new profile' do
        expect(employee.profiles.count).to eq(1)
      end
    end

    context 'when employee department is updated' do
      let!(:old_department) { FactoryGirl.create(:department) }
      let!(:profile) do
        FactoryGirl.create(:profile,
          employee: employee,
          adp_assoc_oid: 'AAABBBCCCDDD',
          adp_employee_id: '123456',
          department: old_department,
          job_title: job_title,
          location: location,
          profile_status: 'active',
          management_position: false,
          manager_adp_employee_id: '654321',
          start_date: Date.new(2017, 0o1, 0o1),
          worker_type: worker_type,
          business_unit: business_unit)
      end

      before do
        w_hash = parser.gen_worker_hash(json['workers'][0])
        described_class.new.update_employee(employee, w_hash)
      end

      it 'updates the current profile' do
        expect(employee.department).to eq(department)
      end

      it 'has one profile' do
        expect(employee.profiles.count).to eq(1)
      end

      it 'creates an emp delta with the change' do
        expect(employee.emp_deltas.count).to eq(1)
        expect(employee.emp_deltas.last.before).to eq('department_id' => old_department.id.to_s)
        expect(employee.emp_deltas.last.after).to eq('department_id' => department.id.to_s)
      end
    end

    context 'when employee basic info and profile info changes' do
      let!(:old_location) { FactoryGirl.create(:location) }
      let!(:profile) do
        FactoryGirl.create(:profile,
          employee: employee,
          adp_assoc_oid: 'AAABBBCCCDDD',
          adp_employee_id: '123456',
          department: department,
          job_title: job_title,
          location: old_location,
          profile_status: 'active',
          management_position: false,
          manager_adp_employee_id: '654321',
          start_date: Date.new(2017, 1, 1),
          worker_type: worker_type,
          business_unit: business_unit)
      end

      before do
        employee.last_name = 'Good All'
        employee.save
        w_hash = parser.gen_worker_hash(json['workers'][0])
        profiler = described_class.new
        profiler.update_employee(employee, w_hash)
      end

      it 'has one profile' do
        expect(employee.profiles.count).to eq(1)
      end

      it 'updates the employee info' do
        expect(employee.last_name).to eq('Goodall')
      end

      it 'updates the profile info' do
        expect(employee.location).to eq(location)
      end

      it 'creates an emp delta' do
        expect(employee.emp_deltas.count).to eq(1)
        expect(employee.emp_deltas.last.before).to eq(
          'last_name' => 'Good All', 'location_id' => old_location.id.to_s
        )
        expect(employee.emp_deltas.last.after).to eq(
          'last_name' => 'Goodall', 'location_id' => location.id.to_s
        )
      end
    end

    context 'when address changes' do
      let(:remote_json) { JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/adp_remote_worker.json')) }

      let(:remote) { FactoryGirl.create(:location, kind: 'Remote Location') }
      let(:remote_worker) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Shirley',
          last_name: 'Allansberg')
      end

      let!(:active_profile) do
        FactoryGirl.create(:profile,
          employee: remote_worker,
          profile_status: 'active',
          adp_employee_id: '100015',
          location: remote)
      end

      let!(:address) do
        FactoryGirl.create(:address,
          addressable_type: 'Employee',
          addressable_id: remote_worker.id,
          line_1: '123 Main St.',
          city: 'Los Angeles',
          state_territory: 'CA',
          postal_code: '90028',
          country_id: Country.find_by(iso_alpha_2: 'US'))
      end

      before do
        FactoryGirl.create(:location, kind: 'Remote Location', code: 'GERMA')
        FactoryGirl.create(:worker_type, code: 'TVOL')

        w_hash = parser.gen_worker_hash(remote_json['workers'][0])
        described_class.new.update_employee(remote_worker, w_hash)
      end

      it 'updates street address' do
        expect(remote_worker.address.line_1).to eq('Zeukerstrasse 123')
      end

      it 'updates line 2' do
        expect(remote_worker.address.line_2).to eq(nil)
      end

      it 'updates city' do
        expect(remote_worker.address.city).to eq('Frankfurt')
      end

      it 'updates country' do
        expect(remote_worker.address.country.iso_alpha_2).to eq('DE')
      end
    end

    context 'when worker address is added' do
      let(:remote_json) { JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/adp_remote_worker.json')) }

      let(:remote) { FactoryGirl.create(:location, kind: 'Remote Location') }
      let(:remote_worker) do
        FactoryGirl.create(:employee,
          status: 'active',
          first_name: 'Shirley',
          last_name: 'Allansberg')
      end

      let!(:active_profile) do
        FactoryGirl.create(:profile,
          employee: remote_worker,
          profile_status: 'active',
          adp_employee_id: '100015',
          location: remote)
      end

      before do
        FactoryGirl.create(:location, kind: 'Remote Location', code: 'GERMA')
        FactoryGirl.create(:worker_type, code: 'TVOL')

        w_hash = parser.gen_worker_hash(remote_json['workers'][0])
        described_class.new.update_employee(remote_worker, w_hash)
      end

      it 'creates an address for worker' do
        expect(remote_worker.address.present?).to be(true)
      end

      it 'has the right street address' do
        expect(remote_worker.address.line_1).to eq('Zeukerstrasse 123')
      end

      it 'has the right city' do
        expect(remote_worker.address.city).to eq('Frankfurt')
      end

      it 'has the right territory' do
        expect(remote_worker.address.state_territory).to eq('Hessen')
      end

      it 'has the right postal code' do
        expect(remote_worker.address.postal_code).to eq('5384980')
      end

      it 'has the right country' do
        expect(remote_worker.address.country.iso_alpha_2).to eq('DE')
      end
    end

    context 'when worker type changes' do
      let!(:old_worker_type) { FactoryGirl.create(:worker_type, code: 'OLD') }
      let!(:profile) do
        FactoryGirl.create(:profile,
          employee: employee,
          adp_assoc_oid: 'AAABBBCCCDDD',
          adp_employee_id: '123456',
          department: department,
          job_title: job_title,
          location: location,
          profile_status: 'active',
          management_position: false,
          manager_adp_employee_id: '654321',
          start_date: Date.new(2017, 0o1, 0o1),
          worker_type: old_worker_type,
          business_unit: business_unit)
      end

      before do
        w_hash = parser.gen_worker_hash(json['workers'][0])
        described_class.new.update_employee(employee, w_hash)
      end

      it 'creates a new profile' do
        expect(employee.profiles.count).to eq(2)
      end

      it 'has the same worker status' do
        expect(employee.status).to eq('active')
      end

      it 'terminates the old profile' do
        expect(employee.reload.profiles.terminated.reorder(:created_at).last).to eq(profile)
        expect(employee.reload.profiles.terminated.reorder(:created_at).last.primary).to eq(false)
      end

      it 'has an active profile' do
        expect(employee.current_profile.profile_status).to eq('active')
      end

      it 'has the right primary profile' do
        expect(employee.reload.current_profile.primary).to be(true)
      end

      it 'creates an emp delta with the changes' do
        expect(employee.emp_deltas.last.before).to eq('worker_type_id' => old_worker_type.id.to_s)
        expect(employee.emp_deltas.last.after).to eq('worker_type_id' => worker_type.id.to_s)
      end
    end

    context 'when business unit changes' do
      let!(:old_business_unit) { FactoryGirl.create(:business_unit, code: 'OLD') }
      let!(:profile) do
        FactoryGirl.create(:profile,
          employee: employee,
          adp_assoc_oid: 'AAABBBCCCDDD',
          adp_employee_id: '123456',
          department: department,
          job_title: job_title,
          location: location,
          profile_status: 'active',
          management_position: false,
          manager_adp_employee_id: '654321',
          start_date: Date.new(2017, 0o1, 0o1),
          worker_type: worker_type,
          business_unit: old_business_unit)
      end

      before do
        w_hash = parser.gen_worker_hash(json['workers'][0])
        described_class.new.update_employee(employee, w_hash)
      end

      it 'has the right business unit' do
        expect(employee.reload.current_profile.business_unit.code).to eq('OTUS')
      end
    end

    context 'when manager changes' do
      let!(:old_top_manager) { FactoryGirl.create(:employee) }
      let!(:old_manager) { FactoryGirl.create(:employee, manager: top_manager, parent_id: old_top_manager.id) }

      before do
        employee.manager_id = old_manager.id
        employee.save
        FactoryGirl.create(:profile,
          employee: employee,
          adp_assoc_oid: 'AAABBBCCCDDD',
          adp_employee_id: '123456',
          department: department,
          job_title: job_title,
          location: location,
          profile_status: 'active',
          management_position: false,
          manager_adp_employee_id: '654321',
          start_date: Date.new(2017, 0o1, 0o1),
          worker_type: worker_type)
        w_hash = parser.gen_worker_hash(json['workers'][0])
        described_class.new.update_employee(employee, w_hash)
      end

      it 'assigns new manager' do
        expect(employee.manager).to eq(manager)
      end

      it 'assigns new descendants for manager' do
        expect(manager.descendants).to include(employee)
      end

      it 'assigns new ancestors for employee' do
        expect(employee.ancestors).to include(manager)
        expect(employee.ancestors).to include(top_manager)
        expect(employee.ancestors).not_to include(old_top_manager)
        expect(employee.ancestors).not_to include(old_manager)
      end

      it 'old manager has right descendants' do
        expect(old_manager.descendants).not_to include(employee)
      end

      it 'new reporting chain has right descendants' do
        expect(top_manager.descendants).to include(employee)
      end

      it 'old reporting chain has right descendants' do
        expect(old_top_manager.descendants).not_to include(employee)
      end
    end
  end

  describe '#new_employee' do
    subject(:new_employee) { Employee.reorder(:created_at).last }

    let(:hire_json) { File.read(Rails.root.to_s + '/spec/fixtures/adp_hire_event.json') }
    let(:event) do
      FactoryGirl.create(:adp_event,
        status: 'new',
        json: hire_json)
    end

    before do
      FactoryGirl.create(:worker_type, code: 'OLFR')
      described_class.new.new_employee(event)
    end

    it 'creates an employee record with the right name' do
      expect(new_employee.first_name).to eq('Hire')
      expect(new_employee.last_name).to eq('Testone')
    end

    it 'has the right status' do
      expect(new_employee.status).to eq('created')
    end

    it 'has the right hire date' do
      expect(new_employee.hire_date).to eq(Date.new(2017, 1, 23))
    end

    it 'has the right contract end date' do
      expect(new_employee.contract_end_date).to eq(nil)
    end

    it 'has an address' do
      expect(new_employee.addresses.count).to eq(1)
    end

    it 'has the right address information' do
      expect(new_employee.address.state_territory).to eq('MA')
    end

    it 'has the right address country' do
      expect(new_employee.address.country.iso_alpha_2).to eq('US')
    end

    it 'creates an employee profile' do
      expect(new_employee.profiles.count).to eq(1)
    end

    it 'gives the profile the correct status' do
      expect(new_employee.profiles.last.profile_status).to eq('pending')
    end

    it 'assigns the employee id to the profile' do
      expect(new_employee.profiles.last.adp_employee_id).to eq('if0rcdig4')
    end

    it 'has the right worker type' do
      expect(new_employee.worker_type.code).to eq('OLFR')
    end

    it 'has the right business title' do
      expect(new_employee.business_card_title).to eq('Account Executive')
    end

    it 'assigns the correct start date' do
      expect(new_employee.profiles.last.start_date).to eq(Date.new(2017, 1, 23))
    end

    it 'assigns a current profile' do
      expect(new_employee.current_profile.primary).to be(true)
    end

    it 'has the right manager' do
      expect(new_employee.manager).to eq(manager)
    end

    it 'has the right ancestors' do
      expect(new_employee.ancestors).to include(top_manager)
      expect(manager.descendants).to include(new_employee)
      expect(top_manager.descendants).to include(new_employee)
    end
  end

  describe '#build_employee' do
    subject(:employee) { described_class.new.build_employee(event) }

    let(:hire_json) { File.read(Rails.root.to_s + '/spec/fixtures/adp_hire_event.json') }
    let(:event) do
      FactoryGirl.create(:adp_event,
        status: 'new',
        json: hire_json)
    end

    before do
      FactoryGirl.create(:worker_type, code: 'OLFR')
    end

    it 'does not persist the employee' do
      expect(employee.persisted?).to eq(false)
    end

    it 'builds an employee object with a name' do
      expect(employee.first_name).to eq('Hire')
      expect(employee.last_name).to eq('Testone')
    end

    it 'has the right hire date' do
      expect(employee.hire_date).to eq(Date.new(2017, 1, 23))
    end

    it 'builds a profile for the employee with the right info' do
      expect(employee.worker_type.code).to eq('OLFR')
    end
  end
end
