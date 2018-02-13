require 'rails_helper'

describe EmployeeQuery, type: :query do
  let!(:contractor) do
    FactoryGirl.create(:contract_worker,
      status: 'active',
      request_status: 'none',
      contract_end_date: Date.new(2017, 12, 1),
      termination_date: nil)
  end

  let!(:cont_2) do
    FactoryGirl.create(:contract_worker,
      status: 'active',
      contract_end_date: Date.new(2017, 11, 11),
      termination_date: Date.new(2017, 12, 1))
  end

  describe '#contract_end_reminder_group' do
    before do
      Timecop.freeze(Time.new(2017, 11, 17, 17, 0, 0, '+00:00'))
    end

    after do
      Timecop.return
    end

    it 'includes correct contractors' do
      expect(EmployeeQuery.new.contract_end_reminder_group).to eq([contractor])
    end
  end

  describe '#hr_contractor_notices' do
    before do
      Timecop.freeze(Time.new(2017, 11, 10, 17, 0, 0, '+00:00'))
    end

    after do
      Timecop.return
    end

    it 'includes correct contractors' do
      expect(EmployeeQuery.new.hr_contractor_notices).to eq([contractor])
    end
  end
end
