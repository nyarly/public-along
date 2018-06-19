require 'rails_helper'

RSpec.describe OffboardingForm do
  let!(:employee) { FactoryGirl.create(:regular_employee) }
  let(:user)      { FactoryGirl.create(:user, employee: employee) }
  let(:offboard)  { FactoryGirl.create(:regular_employee, request_status: 'waiting') }
  let(:emp_trans) { FactoryGirl.build(:emp_transaction, kind: 'offboarding', user: user, employee: offboard) }

  describe '#save' do
    subject(:offboarding_form) { OffboardingForm.new(params) }

    let(:params) do
      {
        archive_data: true,
        replacement_hired: true,
        forward_email_id: employee.id,
        reassign_salesforce_id: employee.id,
        transfer_google_docs_id: employee.id
      }
    end

    before do
      offboarding_form.emp_transaction = emp_trans
      offboarding_form.employee = offboard
    end

    it 'creates an emp transaction' do
      expect {
        offboarding_form.save
      }.to change { EmpTransaction.count }.by(1)
    end

    it 'creates an emp transaction with the right info' do
      offboarding_form.save
      expect(offboarding_form.emp_transaction.user_id).to eq(user.id)
      expect(offboarding_form.emp_transaction.employee_id).to eq(offboard.id)
      expect(offboarding_form.emp_transaction.kind).to eq('offboarding')
    end

    it 'creates one offboarding info' do
      expect {
        offboarding_form.save
      }.to change { OffboardingInfo.count }.by(1)
    end

    it 'creates an offboarding info with the right information' do
      offboarding_form.save
      expect(offboarding_form.emp_transaction.offboarding_infos.first.archive_data)
        .to eq(true)
      expect(offboarding_form.emp_transaction.offboarding_infos.first.replacement_hired)
        .to eq(true)
      expect(offboarding_form.emp_transaction.offboarding_infos.first.forward_email_id)
        .to eq(employee.id)
      expect(offboarding_form.emp_transaction.offboarding_infos.first.reassign_salesforce_id)
        .to eq(employee.id)
      expect(offboarding_form.emp_transaction.offboarding_infos.first.transfer_google_docs_id)
        .to eq(employee.id)
    end

    it 'updates the employee request status' do
      offboarding_form.save
      expect(offboard.reload.request_status).to eq('completed')
    end
  end
end
