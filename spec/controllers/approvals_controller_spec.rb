require 'rails_helper'

RSpec.describe ApprovalsController, type: :controller do
  let!(:approval) { FactoryGirl.create(:approval, status: 'requested') }
  let(:employee)  { FactoryGirl.create(:employee) }
  let!(:user)     { FactoryGirl.create(:user, employee: employee) }

  before do
    login_as user
  end

  describe 'GET #index' do
    it 'assigns all approvals as @approvals' do
      should_authorize(:index, Approval)
      get :index
      expect(assigns(:approvals)).to include(approval)
    end
  end

  describe 'GET #show' do
    it 'assigns the requested approval as @approval' do
      should_authorize(:show, approval)
      get :show, id: approval.id
      expect(assigns(:approval)).to eq(approval)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested approval as @approval' do
      should_authorize(:edit, approval)
      get :edit, id: approval.id
      expect(assigns(:approval)).to eq(approval)
    end
  end

  describe 'PUT #update' do
    let(:request)   { FactoryGirl.create(:emp_transaction, employee: employee) }
    let(:approval)  { FactoryGirl.create(:approval, request_emp_transaction: request, status: 'requested') }
    let(:approver)  { FactoryGirl.create(:approver_designation) }

    before do
      should_authorize(:update, approval)
    end

    context 'with valid params' do
      let!(:valid_attributes) do
        {
          notes: 'notes',
          user_id: user.id,
          request_emp_transaction_id: request.id,
          approver_designation_id: approver.id
        }
      end

      before do
        put :update, id: approval.id, approval_form: valid_attributes, commit: 'approve'
        approval.reload
      end

      it 'updates the requested approval' do
        expect(approval.status).to eq('approved')
      end

      it 'assigns the requested approval as @approval' do
        expect(assigns(:approval)).to eq(approval)
      end

      it 'redirects to the approval' do
        expect(response).to redirect_to(approval)
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        {
          notes: 'notes',
          user_id: user.id,
          request_emp_transaction_id: request.id,
          approver_designation_id: approver.id
        }
      end

      it 'assigns the approval as @approval' do
        put :update, id: approval.id, approval_form: invalid_attributes, commit: 'somethingelse'
        expect(assigns(:approval)).to eq(approval)
      end

      it "re-renders the 'edit' template" do
        put :update, id: approval.id, approval_form: invalid_attributes, commit: 'somethingelse'
        expect(response).to render_template('edit')
      end
    end
  end
end
