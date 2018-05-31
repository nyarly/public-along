require 'rails_helper'

describe Employees::WithExpiringContract, type: :query do
  describe '.call' do
    before do
      Timecop.freeze(Time.new(2018, 5, 25, 9, 0, 0, '-07:00'))
    end

    after do
      Timecop.return
    end

    context 'when contract ends in 2 weeks' do
      subject(:query) { Employees::WithExpiringContract.call }

      let!(:expiring) do
        FactoryGirl.create(:contract_worker,
          contract_end_date: Date.new(2018, 6, 8),
          termination_date: nil)
      end

      it 'query includes contractor' do
        expect(query).to include(expiring)
      end
    end

    context 'when expiring contract has termination date' do
      subject(:query) { Employees::WithExpiringContract.call }


      let!(:termination_pending) do
        FactoryGirl.create(:contract_worker,
          contract_end_date: Date.new(2018, 6, 8),
          termination_date: Date.new(2018, 6, 8))
      end

      it 'query does not include contractor' do
        expect(query).not_to include(termination_pending)
      end
    end

    context 'when contract ended early' do
      subject(:query) { Employees::WithExpiringContract.call }

      let!(:early_termination) do
        FactoryGirl.create(:contract_worker,
          contract_end_date: Date.new(2018, 6, 8),
          termination_date: Date.new(2018, 1, 1))
      end

      it 'query does not include contractor' do
        expect(query).not_to include(early_termination)
      end
    end

    context 'when provided worker type kind' do
      subject(:query) { Employees::WithExpiringContract.call(worker_type_kind: 'Temporary') }

      let!(:temp_worker) do
        FactoryGirl.create(:temp_worker,
          contract_end_date: Date.new(2018, 6, 8),
          termination_date: nil)
      end

      it 'includes temp worker' do
        expect(query).to include(temp_worker)
      end
    end

    context 'when provided time range' do
      subject(:query) { Employees::WithExpiringContract.call(time_range: 3.weeks) }

      let!(:contractor) do
        FactoryGirl.create(:contract_worker,
          contract_end_date: Date.new(2018, 6, 15))
      end

      it 'includes contractor' do
        expect(query).to include(contractor)
      end
    end
  end
end
