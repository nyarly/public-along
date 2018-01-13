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
      kind: "Security Access",
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
      get :new, { employee_id: employee.id, kind: "Security Access", user_emp_id: "12345"}
      expect(assigns(:emp_transaction)).to be_a_new(EmpTransaction)
      expect(assigns(:employee)).to eq(employee)
      expect(assigns(:manager_user)).to eq(user)
      expect(assigns(:kind)).to eq("Security Access")
    end
  end

  describe "POST #create" do
    before :each do
      should_authorize(:create, EmpTransaction)
    end

    context "with valid params" do
      it "creates a new EmpTransaction" do
        allow(TechTableMailer).to receive_message_chain(:permissions, :deliver_now)
        expect {
          post :create, { :manager_entry => valid_attributes }
        }.to change(EmpTransaction, :count).by(1)
      end

      it "assigns a newly created emp_transaction as @emp_transaction" do
        allow(TechTableMailer).to receive_message_chain(:permissions, :deliver_now)
        post :create, { :manager_entry => valid_attributes }
        expect(assigns(:emp_transaction)).to be_a(EmpTransaction)
        expect(assigns(:emp_transaction)).to be_persisted
      end

      it "redirects to the created emp_transaction" do
        allow(TechTableMailer).to receive_message_chain(:permissions, :deliver_now)
        post :create, { :manager_entry => valid_attributes }
        expect(response).to redirect_to(emp_transaction_path(EmpTransaction.last))
      end

      it "calls the emp transaction worker" do
        expect(EmpTransactionWorker).to receive(:perform_async)
        post :create, { :manager_entry => valid_attributes }
      end

      it "only sends the data once" do
        expect {
          post :create, {:manager_entry => valid_attributes}
          post :create, {:manager_entry => valid_attributes}
        }.to change(EmpTransaction, :count).by(1)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved emp_transaction as @emp_transaction" do
        post :create, {:manager_entry => invalid_attributes}
        expect(assigns(:emp_transaction)).to be_a_new(EmpTransaction)
      end

      it "re-renders the 'new' template" do
        post :create, {:manager_entry => invalid_attributes}
        expect(response).to redirect_to("http://test.host/emp_transactions/new?employee_id=#{employee.id}&kind=Something+else&submission_token=present&user_id=12345")
      end

      it "does not send an email to Tech Table" do
        expect(TechTableMailer).to_not receive(:permissions)
        post :create, {:manager_entry => invalid_attributes}
      end
    end
  end
end
