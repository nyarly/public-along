require 'rails_helper'

RSpec.describe OnboardingForm do
  let!(:employee) { FactoryGirl.create(:regular_employee) }
  let(:user)      { FactoryGirl.create(:user, employee: employee) }
  let!(:new_hire) { FactoryGirl.create(:pending_employee) }
  let(:service)   { double(EmployeeService::Onboard) }
  let(:emp_trans) { FactoryGirl.build(:emp_transaction, kind: 'onboarding', user: user, employee: new_hire) }

  describe '#save' do
    subject(:onboarding_form) { OnboardingForm.new(params) }

    let(:params) do
      {
        buddy_id: employee.id,
        cw_email: 'true',
        cw_google_membership: 'true',
      }
    end

    before do
      onboarding_form.emp_transaction = emp_trans
      onboarding_form.employee = new_hire

      allow(TechTableWorker).to receive(:perform_async)
      allow(EmployeeService::Onboard).to receive(:new).and_return(service)
      allow(service).to receive(:new_worker)
    end

    it 'creates an emp transaction' do
      expect {
        onboarding_form.save
      }.to change { EmpTransaction.count }.by(1)
    end

    it 'creates an emp transaction with the right info' do
      onboarding_form.save
      expect(onboarding_form.emp_transaction.user).to eq(user)
      expect(onboarding_form.emp_transaction.kind).to eq('onboarding')
      expect(onboarding_form.emp_transaction.employee).to eq(new_hire)
    end

    it 'creates one onboarding info' do
      expect {
        onboarding_form.save
      }.to change { OnboardingInfo.count }.by(1)
    end

    it 'creates an onboarding info with the right information' do
      onboarding_form.save
      expect(onboarding_form.emp_transaction.onboarding_infos.first.buddy_id).to eq(employee.id)
      expect(onboarding_form.emp_transaction.onboarding_infos.first.cw_email).to eq(true)
      expect(onboarding_form.emp_transaction.onboarding_infos.first.cw_google_membership).to eq(true)
    end

    it 'updates the employee request status' do
      onboarding_form.save
      expect(new_hire.reload.request_status).to eq('completed')
    end
  end
end
