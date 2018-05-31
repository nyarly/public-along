require 'rails_helper'

describe EmployeeQuery, type: :query do
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
end
