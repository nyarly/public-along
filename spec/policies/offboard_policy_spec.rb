require 'rails_helper'

describe OffboardPolicy, type: :policy do
  describe '#offboarded_contractor?' do
    context 'when terminated contractor does not have termination date' do
      let(:offboarded_contractor) do
        FactoryGirl.create(:employee,
          status: 'terminated',
          contract_end_date: 1.day.ago,
          termination_date: nil)
      end

      before do
        FactoryGirl.create(:profile,
          employee: offboarded_contractor,
          profile_status: 'terminated',
          end_date: 1.day.ago)
      end

      it 'is true' do
        policy = OffboardPolicy.new(offboarded_contractor).offboarded_contractor?
        expect(policy).to be(true)
      end
    end

    context 'when active contractor does not have termination date' do
      let(:contractor) do
        FactoryGirl.create(:employee,
          status: 'active',
          contract_end_date: 1.week.from_now,
          termination_date: nil)
      end

      before do
        FactoryGirl.create(:profile,
          employee: contractor,
          profile_status: 'active',
          end_date: nil)
      end

      it 'is false' do
        policy = OffboardPolicy.new(contractor).offboarded_contractor?
        expect(policy).to be(false)
      end
    end
  end

  describe '#offboarded?' do
    context 'when worker has offboarded_at datetime' do
      context 'when worker has terminated status' do
        let(:worker) do
          FactoryGirl.create(:employee,
            status: 'terminated',
            offboarded_at: 1.day.ago)
        end

        it 'is true' do
          policy = OffboardPolicy.new(worker).offboarded?
          expect(policy).to be(true)
        end
      end

      context 'when worker does not have terminated status' do
        let(:worker) do
          FactoryGirl.create(:employee,
            status: 'active',
            offboarded_at: 1.day.ago)
        end

        it 'is false' do
          policy = OffboardPolicy.new(worker).offboarded?
          expect(policy).to be(false)
        end
      end
    end

    context 'when worker does not have offboarded_at datetime' do
      context 'when worker has terminated status' do
        let(:worker) do
          FactoryGirl.create(:employee,
            status: 'terminated')
        end

        it 'is false' do
          policy = OffboardPolicy.new(worker).offboarded?
          expect(policy).to be(false)
        end
      end

      context 'when worker does not have terminated status' do
        let(:worker) do
          FactoryGirl.create(:employee,
            status: 'active')
        end

        it 'is false' do
          policy = OffboardPolicy.new(worker).offboarded?
          expect(policy).to be(false)
        end
      end
    end
  end
end
