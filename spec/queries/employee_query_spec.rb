require 'rails_helper'

describe EmployeeQuery, type: :query do
  describe '#contract_end_reminder_group' do
    let!(:contractor) do
      FactoryGirl.create(:contract_worker,
        status: 'active',
        request_status: 'none',
        contract_end_date: Date.new(2017, 12, 1),
        termination_date: nil)
    end

    before do
      Timecop.freeze(Time.new(2017, 11, 17, 17, 0, 0, '+00:00'))
      FactoryGirl.create(:contract_worker,
        status: 'active',
        contract_end_date: Date.new(2017, 11, 11),
        termination_date: Date.new(2017, 12, 1))
    end

    after do
      Timecop.return
    end

    it 'has correct contractors' do
      expect(EmployeeQuery.new.contract_end_reminder_group).to eq([contractor])
    end
  end

  describe '#active_regular_workers' do
    context 'when regular worker' do
      subject(:workers) { EmployeeQuery.new.active_regular_workers }

      let!(:active_employee) { FactoryGirl.create(:active_employee) }
      let!(:terminated_employee) { FactoryGirl.create(:terminated_employee) }
      let!(:pending_employee) { FactoryGirl.create(:pending_employee) }

      it 'includes active' do
        expect(workers).to eq([active_employee])
      end
    end

    context 'when contractor' do
      subject(:workers) { EmployeeQuery.new.active_regular_workers }

      let!(:active_contractor) do
        FactoryGirl.create(:contractor,
          profile_status: 'active',
          employee_args: { status: 'active' })
      end

      let!(:pending_contractor) do
        FactoryGirl.create(:contractor,
          employee_args: { status: 'pending' })
      end

      let!(:terminated_contractor) do
        FactoryGirl.create(:contractor,
          profile_status: 'terminated',
          employee_args: { status: 'terminated' })
      end

      it 'never included' do
        expect(workers).to eq([])
      end
    end

    context 'when temp' do
      subject(:workers) { EmployeeQuery.new.active_regular_workers }

      let!(:active_temp) do
        FactoryGirl.create(:temp,
          profile_status: 'active',
          employee_args: { status: 'active' })
      end

      let!(:pending_temp) do
        FactoryGirl.create(:temp,
          employee_args: { status: 'pending' })
      end

      let!(:terminated_temp) do
        FactoryGirl.create(:temp,
          profile_status: 'terminated',
          employee_args: { status: 'terminated' })
      end

      it 'never included' do
        expect(workers).to eq([])
      end
    end
  end

  describe '#concur_upload_group' do
    before do
      Timecop.freeze(Time.new(2018, 2, 14, 16, 0, 0, '+00:00'))
    end

    after do
      Timecop.return
    end

    context 'when employee started today' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let(:new_employee) { FactoryGirl.create(:employee, status: 'active') }

      before do
        FactoryGirl.create(:profile,
          employee: new_employee,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 14))
      end

      it 'they are included' do
        expect(upload_group).to include(new_employee)
      end
    end

    context 'when employee starts tomorrow' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let(:new_employee) { FactoryGirl.create(:employee, status: 'active') }

      before do
        FactoryGirl.create(:profile,
          employee: new_employee,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 15))
      end

      it 'they are not included' do
        expect(upload_group).not_to include(new_employee)
      end
    end

    context 'when worker has a change' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let(:changed_employee) { FactoryGirl.create(:employee, status: 'active') }

      before do
        FactoryGirl.create(:profile,
          employee: changed_employee,
          profile_status: 'active')
        FactoryGirl.create(:emp_delta,
          employee: changed_employee,
          created_at: Time.new(2018, 2, 14, 8, 0, 0, '+00:00'),
          before: { 'business_title' => 'biz title' },
          after: { 'business_title' => 'business title' })
      end

      it 'they are included' do
        expect(upload_group).to include(changed_employee)
      end
    end

    context 'when worker has a change and starts' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let(:new_and_changed_employee) { FactoryGirl.create(:employee, status: 'active') }

      before do
        FactoryGirl.create(:profile,
          employee: new_and_changed_employee,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 14))
        FactoryGirl.create(:emp_delta,
          employee: new_and_changed_employee,
          created_at: Time.new(2018, 2, 14, 8, 0, 0, '+00:00'),
          before: { 'business_title' => 'biz' },
          after: { 'business_title' => 'niz' })
      end

      it 'is only included once' do
        expect(upload_group).to eq([new_and_changed_employee])
      end
    end

    context 'when worker was terminated yesterday' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let!(:terminated_employee) do
        FactoryGirl.create(:terminated_employee,
          termination_date: Date.new(2018, 2, 13))
      end

      it 'they are included' do
        expect(upload_group).to eq([terminated_employee])
      end
    end

    context 'when worker terminated today' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let(:term_today) do
        FactoryGirl.create(:active_employee,
          termination_date: Date.new(2018, 2, 14))
      end

      it 'they are not included' do
        expect(upload_group).not_to eq([term_today])
      end
    end

    context 'when worker is not regular worker' do
      subject(:upload_group) { EmployeeQuery.new.concur_upload_group }

      let(:temp) { FactoryGirl.create(:employee, status: 'active') }
      let(:contractor) { FactoryGirl.create(:contract_worker, status: 'active') }

      before do
        FactoryGirl.create(:temp,
          employee: temp,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 14))
        FactoryGirl.create(:emp_delta,
          employee: contractor,
          created_at: Time.new(2018, 2, 14, 8, 0, 0, '+00:00'),
          before: { 'business_title' => 'biz' },
          after: { 'business_title' => 'niz' })
      end

      it 'does not include contractors' do
        expect(upload_group).not_to include(contractor)
      end

      it 'does not include temps' do
        expect(upload_group).not_to include(temp)
      end
    end
  end

  describe '#hr_contractor_notices' do
    let(:contractor) do
      FactoryGirl.create(:contract_worker,
        status: 'active',
        contract_end_date: Date.new(2018, 2, 23))
    end

    before do
      Timecop.freeze(Time.new(2018, 2, 2, 17, 0, 0, '+00:00'))
    end

    after do
      Timecop.return
    end

    it 'includes correct contractors' do
      expect(EmployeeQuery.new.hr_contractor_notices).to eq([contractor])
    end
  end
end
