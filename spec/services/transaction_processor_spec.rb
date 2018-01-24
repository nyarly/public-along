require 'rails_helper'

describe TransactionProcesser, type: :service do
  let(:pending)   { FactoryGirl.create(:employee, status: 'pending') }
  let(:pend_p)    { FactoryGirl.create(:profile,
                    employee: pending,
                    profile_status: 'pending') }
  let(:onboard)   { FactoryGirl.create(:emp_transaction,
                    kind: 'Onboarding',
                    employee: pending) }
  let(:on_info)   { FactoryGirl.create(:onboarding_info,
                    emp_transaction: onboard) }
  let(:active)    { FactoryGirl.create(:employee, status: 'active') }
  let(:act_p)     { FactoryGirl.create(:profile,
                    employee: active,
                    profile_status: 'active') }
  let(:offboard)  { FactoryGirl.create(:emp_transaction,
                    kind: 'Offboarding',
                    employee: active) }
  let(:odd_info)  { FactoryGirl.create(:onboarding_info,
                    emp_transaction: offboard) }

  let(:on_service) { double(EmployeeService::Onboard) }


  context '#call' do

    it 'onboards new worker' do
      expect(TechTableWorker).to receive(:perform_async)
      transaction = TransactionProcesser.new(onboard).call
    end

    it 'offboards' do
      expect(TechTableWorker).not_to receive(:perform_async)
      transaction = TransactionProcesser.new(offboard).call
      expect(transaction).to eq(true)
    end
  end
end
