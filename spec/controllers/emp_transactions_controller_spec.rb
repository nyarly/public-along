require 'rails_helper'

RSpec.describe EmpTransactionsController, type: :controller do

  let!(:employee)        { FactoryGirl.create(:regular_employee) }
  let!(:profile)         { FactoryGirl.create(:active_profile,
                           employee: employee,
                           adp_employee_id: "12345") }
  let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
                           employee: employee,
                           user: user) }
  let!(:emp_mach_bundle) { FactoryGirl.create(:emp_mach_bundle, emp_transaction: emp_transaction) }
  let!(:machine_bundle)  { FactoryGirl.create(:machine_bundle) }
  let!(:buddy)           { FactoryGirl.create(:regular_employee) }
  let!(:user)            { FactoryGirl.create(:user,
                           role_names:["Admin"],
                           adp_employee_id: "12345") }
  let(:emp_worker)       { double(EmpTransactionWorker) }

  let(:valid_attributes) {
    {
      kind: 'security_access',
      employee_id: employee.id,
      user_id: user.id,
      machine_bundle_id: machine_bundle.id,
      submission_token: 'present'
    }
  }

  let(:invalid_attributes) {
    {
      user_id: "12345",
      kind: "Something else",
      employee_id: employee.id,
      submission_token: 'present'
    }
  }

  before :each do
    login_as user
    session[:submission_token] = 'present'
  end

  describe "GET #index" do
    it "assigns all emp_transactions as @emp_transactions" do
      should_authorize(:index, EmpTransaction)
      get :index
      expect(assigns(:emp_transactions)).to eq([emp_transaction])
    end
  end

  describe "GET #show" do
    it "assigns the requested emp_transaction as @emp_transaction" do
      get :show, {:id => emp_transaction.id}
      expect(assigns(:emp_transaction)).to eq(emp_transaction)
    end
  end

  describe "GET #new" do
    it "assigns a new emp_transaction as @emp_transaction" do
      should_authorize(:new, EmpTransaction)
      get :new, { employee_id: employee.id, kind: 'security_access' }
      expect(assigns(:manager_entry).emp_transaction).to be_a(EmpTransaction)
      expect(assigns(:manager_entry).employee).to eq(employee)
      expect(assigns(:manager_entry).kind).to eq('security_access')
    end
  end

  describe "POST #create" do
    context "with valid params" do
      before do
        should_authorize(:create, EmpTransaction)
      end

      it "creates a new EmpTransaction" do
        expect {
          post :create, { manager_entry: valid_attributes }
        }.to change(EmpTransaction, :count).by(1)
      end

      it "assigns a newly created emp_transaction as @emp_transaction" do
        post :create, { manager_entry: valid_attributes }
        expect(assigns(:emp_transaction)).to be_a(EmpTransaction)
        expect(assigns(:emp_transaction)).to be_persisted
      end

      it "redirects to the created emp_transaction" do
        post :create, { manager_entry: valid_attributes }
        expect(response).to redirect_to(emp_transaction_path(EmpTransaction.last))
      end

      it "only sends the data once" do
        expect {
          post :create, { manager_entry: valid_attributes }
          post :create, { manager_entry: valid_attributes }
        }.to change(EmpTransaction, :count).by(1)
      end
    end

    context 'with invalid form kind' do
      it 'redirects to root' do
        post :create, { manager_entry: invalid_attributes }
        expect(response).to redirect_to(root_path)
      end

      it 'displays an error' do
        post :create, { manager_entry: invalid_attributes }
        expect(flash[:notice]).to eq('Invalid form.')
      end
    end
  end
end
