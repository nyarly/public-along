require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe EmpTransactionsController, type: :controller do

  let!(:emp_transaction) { FactoryGirl.create(:emp_transaction, user: user) }
  let!(:emp_mach_bundle) { FactoryGirl.create(:emp_mach_bundle, emp_transaction: emp_transaction) }
  let!(:machine_bundle) { FactoryGirl.create(:machine_bundle) }
  let!(:employee) { FactoryGirl.create(:employee, worker_type_id: worker_type.id) }
  let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Regular")}
  let!(:buddy) { FactoryGirl.create(:employee) }
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"], employee_id: "12345") }

  let(:valid_attributes) {
    {
      kind: "Security Access",
      employee_id: employee.id,
      user_id: user.id,
      machine_bundle_id: machine_bundle.id
    }
  }

  let(:invalid_attributes) {
    {
      user_id: "12345",
      kind: "Something else"
    }
  }

  before :each do
    login_as user
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
          post :create, {:manager_entry => valid_attributes}
        }.to change(EmpTransaction, :count).by(1)
      end

      it "assigns a newly created emp_transaction as @emp_transaction" do
        allow(TechTableMailer).to receive_message_chain(:permissions, :deliver_now)
        post :create, {:manager_entry => valid_attributes}
        expect(assigns(:emp_transaction)).to be_a(EmpTransaction)
        expect(assigns(:emp_transaction)).to be_persisted
      end

      it "redirects to the created emp_transaction" do
        allow(TechTableMailer).to receive_message_chain(:permissions, :deliver_now)
        post :create, {:manager_entry => valid_attributes}
        expect(response).to redirect_to( emp_transaction_path(EmpTransaction.last, emp_id: employee.id))
      end

      it "sends an email to Tech Table" do
        expect(TechTableMailer).to receive_message_chain(:permissions, :deliver_now)
        post :create, {:manager_entry => valid_attributes}
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved emp_transaction as @emp_transaction" do
        post :create, {:manager_entry => invalid_attributes}
        expect(assigns(:emp_transaction)).to be_a_new(EmpTransaction)
      end

      it "re-renders the 'new' template" do
        post :create, {:manager_entry => invalid_attributes}
        expect(response).to redirect_to("http://test.host/emp_transactions/new?kind=Something+else&user_id=12345")
      end

      it "does not send an email to Tech Table" do
        expect(TechTableMailer).to_not receive(:permissions)
        post :create, {:manager_entry => invalid_attributes}
      end
    end
  end
end
