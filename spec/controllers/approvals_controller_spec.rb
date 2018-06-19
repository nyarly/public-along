require 'rails_helper'

RSpec.describe ApprovalsController, type: :controller do
  let!(:approval) { FactoryGirl.create(:approval) }
  let!(:user) { FactoryGirl.create(:user, role_names: ['Admin']) }

  let(:valid_attributes) do
    {
    }
  end

  let(:invalid_attributes) do
    {
      name: nil
    }
  end

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
    before do
      should_authorize(:update, approval)
    end
    context 'with valid params' do
      let(:new_attributes) do
        {
          name: 'New Name',
          code: '123456'
        }
      end

      it 'updates the requested approval' do
        put :update, id: approval.id, approval: new_attributes
        approval.reload
        expect(approval.name).to eq('New Name')
      end

      it 'assigns the requested approval as @approval' do
        put :update, id: approval.id, approval: valid_attributes
        expect(assigns(:approval)).to eq(approval)
      end

      it 'redirects to the approval' do
        put :update, id: approval.id, approval: valid_attributes
        expect(response).to redirect_to(approval)
      end
    end

    context 'with invalid params' do
      it 'assigns the approval as @approval' do
        put :update, id: approval.id, approval: invalid_attributes
        expect(assigns(:approval)).to eq(approval)
      end

      it "re-renders the 'edit' template" do
        put :update, id: approval.id, approval: invalid_attributes
        expect(response).to render_template('edit')
      end
    end
  end
end
