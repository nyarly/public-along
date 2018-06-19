require 'rails_helper'

RSpec.describe NewContractorForm do
  let!(:employee)     { FactoryGirl.create(:regular_employee) }
  let(:user)          { FactoryGirl.create(:user, employee: employee) }
  let(:business_unit) { FactoryGirl.create(:business_unit) }
  let(:location)      { FactoryGirl.create(:location) }
  let(:department)    { FactoryGirl.create(:department) }
  let(:worker_type)   { FactoryGirl.create(:worker_type) }

  describe '#save' do
    context 'with valid params' do
      subject(:contractor_entry) { NewContractorForm.new(params) }
      let(:params) do
        {
          user_id: user.id,
          notes: 'some notes',
          req_or_po_number: '1234',
          legal_approver: 'fname lname',
          first_name: 'contractorfname',
          last_name: 'contractorlname',
          start_date: Date.new(2018, 7, 1),
          contract_end_date: Date.new(2018, 12, 31),
          business_title: 'a title',
          personal_mobile_phone: '888-888-8888',
          personal_email: 'email@example.com',
          manager_id: employee.id,
          business_unit_id: business_unit.id,
          location_id: location.id,
          department_id: department.id,
          worker_type_id: worker_type.id,
          kind: 'new_contractor'
        }
      end

      it 'creates one emp transaction' do
        expect {
          contractor_entry.save
        }.to change { EmpTransaction.count }.by(1)
      end

      it 'creates an emp transaction with the right info' do
        contractor_entry.save
        expect(contractor_entry.emp_transaction.user).to eq(user)
        expect(contractor_entry.emp_transaction.kind).to eq('new_contractor')
        expect(contractor_entry.emp_transaction.notes).to eq('some notes')
      end

      it 'creates one contractor info' do
        expect {
          contractor_entry.save
        }.to change { ContractorInfo.count }.by(1)
      end

      it 'creates a contractor info with the right info' do
        contractor_entry.save
        expect(contractor_entry.contractor_info.req_or_po_number).to eq('1234')
        expect(contractor_entry.contractor_info.legal_approver).to eq('fname lname')
      end

      it 'creates one employee record' do
        expect {
          contractor_entry.save
        }.to change { Employee.count }.by(1)
      end

      it 'creates a new employee with the right info' do
        contractor_entry.save
        expect(contractor_entry.employee.status).to eq('created')
        expect(contractor_entry.employee.first_name).to eq('contractorfname')
        expect(contractor_entry.employee.last_name).to eq('contractorlname')
        expect(contractor_entry.employee.hire_date).to eq(Date.new(2018, 7, 1))
        expect(contractor_entry.employee.contract_end_date).to eq(Date.new(2018, 12, 31))
        expect(contractor_entry.employee.personal_mobile_phone).to eq('888-888-8888')
        expect(contractor_entry.employee.personal_email).to eq('email@example.com')
        expect(contractor_entry.employee.manager_id).to eq(employee.id)
      end

      it 'creates one new profile' do
        expect {
          contractor_entry.save
        }.to change { Profile.count }.by(1)
      end

      it 'creates a profile with the right info' do
        contractor_entry.save
        expect(contractor_entry.employee.current_profile.profile_status).to eq('pending')
        expect(contractor_entry.employee.profiles.count).to eq(1)
        expect(contractor_entry.employee.current_profile.business_title).to eq('a title')
        expect(contractor_entry.employee.current_profile.location).to eq(location)
        expect(contractor_entry.employee.current_profile.department).to eq(department)
        expect(contractor_entry.employee.current_profile.job_title.name).to eq('CONTRACTOR')
        expect(contractor_entry.employee.current_profile.worker_type).to eq(worker_type)
        expect(contractor_entry.employee.current_profile.business_unit).to eq(business_unit)
        expect(contractor_entry.employee.current_profile.start_date).to eq(Date.new(2018, 7, 1))
        expect(contractor_entry.employee.current_profile.end_date).to eq(Date.new(2018, 12, 31))
      end
    end
  end
end
