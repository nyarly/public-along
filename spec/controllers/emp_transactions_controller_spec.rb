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

  let!(:emp_transaction) { FactoryGirl.create(:emp_transaction) }
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:user) { FactoryGirl.create(:user, :role_name => "Admin", employee_id: "12345") }

  let(:valid_attributes) {
    {
      user_id: user.id,
      kind: "Security Access",
      employee_id: employee.id,
      user_emp_id: "12345"
    }
  }

  let(:invalid_attributes) {
    {
      user_id: user.id,
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
      expect(assigns(:manager)).to eq(user)
      expect(assigns(:kind)).to eq("Security Access")
    end
  end

  describe "GET #edit" do
    it "assigns the requested emp_transaction as @emp_transaction" do
      get :edit, {:id => emp_transaction.id}
      expect(assigns(:emp_transaction)).to eq(emp_transaction)
    end
  end

  xdescribe "POST #create" do
    # TODO Need to revisit this when working on equipement request ticket
    before :each do
      should_authorize(:create, EmpTransaction)
    end

    context "with valid params" do
      let(:sas) { double(SecAccessService) }
      it "creates a new EmpTransaction" do
        allow(SecAccessService).to receive(:new).and_return(sas)
        allow(sas).to receive(:apply_ad_permissions).and_return(true)
        expect {
          post :create, {:emp_transaction => valid_attributes}
        }.to change(EmpTransaction, :count).by(1)
      end

      it "assigns a newly created emp_transaction as @emp_transaction" do
        post :create, {:emp_transaction => valid_attributes}
        expect(assigns(:emp_transaction)).to be_a(EmpTransaction)
        expect(assigns(:emp_transaction)).to be_persisted
      end

      it "redirects to the created emp_transaction" do
        post :create, {:emp_transaction => valid_attributes}
        expect(response).to redirect_to(EmpTransaction.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved emp_transaction as @emp_transaction" do
        post :create, {:emp_transaction => invalid_attributes}
        expect(assigns(:emp_transaction)).to be_a_new(EmpTransaction)
      end

      it "re-renders the 'new' template" do
        post :create, {:emp_transaction => invalid_attributes}
        expect(response).to redirect_to(new_emp_transaction_path)
      end
    end
  end

  describe "PUT #update" do
    before :each do
      should_authorize(:update, emp_transaction)
    end

    context "with valid params" do
      let(:new_attributes) {
        {
          user: user,
          kind: "Equipment"
        }
      }

      it "updates the requested emp_transaction" do
        put :update, {:id => emp_transaction.id, :emp_transaction => new_attributes}
        emp_transaction.reload
        expect(emp_transaction.kind).to eq("Equipment")
      end

      it "assigns the requested emp_transaction as @emp_transaction" do
        put :update, {:id => emp_transaction.id, :emp_transaction => valid_attributes}
        expect(assigns(:emp_transaction)).to eq(emp_transaction)
      end

      it "redirects to the emp_transaction" do
        put :update, {:id => emp_transaction.id, :emp_transaction => valid_attributes}
        expect(response).to redirect_to(emp_transaction)
      end
    end

    context "with invalid params" do
      it "assigns the emp_transaction as @emp_transaction" do
        put :update, {:id => emp_transaction.id, :emp_transaction => invalid_attributes}
        expect(assigns(:emp_transaction)).to eq(emp_transaction)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => emp_transaction.id, :emp_transaction => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before :each do
      should_authorize(:destroy, emp_transaction)
    end

    it "destroys the requested emp_transaction" do
      expect {
        delete :destroy, {:id => emp_transaction.id}
      }.to change(EmpTransaction, :count).by(-1)
    end

    it "redirects to the emp_transactions list" do
      delete :destroy, {:id => emp_transaction.id}
      expect(response).to redirect_to(emp_transactions_url)
    end
  end

end
