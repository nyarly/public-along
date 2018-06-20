require 'rails_helper'

RSpec.describe ApprovalForm do
  describe '#save' do
    let(:employee)      { FactoryGirl.create(:employee) }
    let(:user)          { FactoryGirl.create(:user, employee: employee) }
    let(:request)       { FactoryGirl.create(:emp_transaction, employee: employee) }
    let(:approver_role) { FactoryGirl.create(:approver_designation) }
    let(:approval) do
      FactoryGirl.create(:approval,
        status: 'requested',
        request_emp_transaction: request,
        approver_designation: approver_role,
        requested_at: 1.day.ago)
    end

    context 'when approved' do
      subject(:entry) { described_class.new(params) }

      let(:params) do
        {
          approval_id: approval.id,
          approver_designation_id: approver_role.id,
          request_emp_transaction_id: request.id,
          user_id: user.id,
          request_action: 'Approve'
        }
      end

      before do
        Timecop.freeze(Time.new(2018, 7, 1, 0, 0, 0, '-07:00'))
        entry.save
        approval.reload
      end

      it 'creates an emp transaction' do
        expect(approval.emp_transaction.present?).to be(true)
      end

      it 'assigns notes to the emp transaction' do
        expect(approval.emp_transaction.notes).to eq(nil)
      end

      it 'assigns the right kind to the emp transaction' do
        expect(approval.emp_transaction.kind).to eq('approval')
      end

      it 'updates the approval status to approved' do
        expect(approval.status).to eq('approved')
      end

      it 'sets the approved at time' do
        expect(approval.approved_at).to eq(Time.new(2018, 7, 1, 0, 0, 0, '-07:00'))
      end
    end

    context 'when rejected' do
      subject(:entry) { described_class.new(params) }

      let(:params) do
        {
          approval_id: approval.id,
          approver_designation_id: approver_role.id,
          request_emp_transaction_id: request.id,
          user_id: user.id,
          request_action: 'Reject',
          notes: 'not ok'
        }
      end

      before do
        Timecop.freeze(Time.new(2018, 7, 1, 0, 0, 0, '-07:00'))
        entry.save
        approval.reload
      end

      it 'creates an emp transaction' do
        expect(approval.emp_transaction.present?).to be(true)
      end

      it 'assigns notes to the emp transaction' do
        expect(approval.emp_transaction.notes).to eq('not ok')
      end

      it 'assigns the right kind to the emp transaction' do
        expect(approval.emp_transaction.kind).to eq('approval')
      end

      it 'updates the approval status to rejected' do
        expect(approval.status).to eq('rejected')
      end

      it 'sets the rejected at time' do
        expect(approval.rejected_at).to eq(Time.new(2018, 7, 1, 0, 0, 0, '-07:00'))
      end

      it 'does not set approved at time' do
        expect(approval.approved_at).to eq(nil)
      end
    end

    context 'when changes requested' do
      subject(:entry) { described_class.new(params) }

      let(:params) do
        {
          approval_id: approval.id,
          approver_designation_id: approver_role.id,
          request_emp_transaction_id: request.id,
          user_id: user.id,
          request_action: 'Request Changes',
          notes: 'make changes'
        }
      end

      before do
        Timecop.freeze(Time.new(2018, 7, 1, 0, 0, 0, '-07:00'))
        entry.save
        approval.reload
      end

      it 'creates an emp transaction' do
        expect(approval.emp_transaction.present?).to be(true)
      end

      it 'assigns notes to the emp transaction' do
        expect(approval.emp_transaction.notes).to eq('make changes')
      end

      it 'assigns the right kind to the emp transaction' do
        expect(approval.emp_transaction.kind).to eq('approval')
      end

      it 'updates the approval status to rejected' do
        expect(approval.status).to eq('changes_requested')
      end

      it 'sets the rejected at time' do
        expect(approval.rejected_at).to eq(nil)
      end

      it 'does not set approved at time' do
        expect(approval.approved_at).to eq(nil)
      end
    end

    context 'when invalid request action' do
      subject(:entry) { described_class.new(params) }

      let(:params) do
        {
          approval_id: approval.id,
          approver_designation_id: approver_role.id,
          request_emp_transaction_id: request.id,
          user_id: user.id,
          request_action: 'Nefarious doings'
        }
      end

      before do
        Timecop.freeze(Time.new(2018, 7, 1, 0, 0, 0, '-07:00'))
      end

      it 'raises an exception' do
        expect { entry.save }.to raise_error('Request not permitted')
      end
    end
  end
end
