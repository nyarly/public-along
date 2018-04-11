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
