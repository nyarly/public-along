require 'rails_helper'

describe EmployeePolicy, type: :policy do
  describe '.is_conversion?' do
    let(:employee) { FactoryGirl.create(:employee, status: 'active') }
    let(:contractor) do
      FactoryGirl.create(:employee,
        status: 'active',
        contract_end_date: nil,
        termination_date: nil)
    end

    before do
      FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: contractor)
      FactoryGirl.create(:profile,
        profile_status: 'pending',
        employee: contractor)
      FactoryGirl.create(:profile,
        profile_status: 'active',
        employee: employee)
    end

    context 'when conversion' do
      let(:policy) { EmployeePolicy.new(contractor) }

      it 'is true' do
        expect(policy.is_conversion?).to eq(true)
      end
    end

    context 'when not conversion' do
      let(:policy) { EmployeePolicy.new(employee) }

      it 'is false' do
        expect(policy.is_conversion?).to eq(false)
      end
    end
  end

  describe '.manager?' do
    let!(:worker) { FactoryGirl.create(:active_employee) }
    let!(:direct_report) do
      FactoryGirl.create(:active_employee,
        manager_id: worker.id)
    end

    context 'when worker has direct reports' do
      subject(:policy) { EmployeePolicy.new(worker) }

      it 'is true' do
        expect(policy.manager?).to eq(true)
      end
    end

    context 'when worker does not have direct reports' do
      subject(:policy) { EmployeePolicy.new(direct_report) }

      it 'is false' do
        expect(policy.manager?).to eq(false)
      end
    end
  end
end
