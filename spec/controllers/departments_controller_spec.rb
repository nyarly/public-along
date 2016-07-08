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

RSpec.describe DepartmentsController, type: :controller do

  let!(:department) { FactoryGirl.create(:department) }
  let!(:user) { FactoryGirl.create(:user, :role_name => "Admin") }

  let(:valid_attributes) {
    {
      name: "Department name",
      code: "123456"
    }
  }

  let(:invalid_attributes) {
    {
      name: nil
    }
  }

  before :each do
    login_as user
  end

  describe "GET #index" do
    it "assigns all departments as @departments" do
      should_authorize(:index, Department)
      get :index
      expect(assigns(:departments)).to eq([department])
    end
  end

  describe "GET #show" do
    it "assigns the requested department as @department" do
      should_authorize(:show, department)
      get :show, {:id => department.id}
      expect(assigns(:department)).to eq(department)
    end
  end

  describe "GET #new" do
    it "assigns a new department as @department" do
      should_authorize(:new, Department)
      get :new
      expect(assigns(:department)).to be_a_new(Department)
    end
  end

  describe "GET #edit" do
    it "assigns the requested department as @department" do
      should_authorize(:edit, department)
      get :edit, {:id => department.id}
      expect(assigns(:department)).to eq(department)
    end
  end

  describe "POST #create" do
    before :each do
      should_authorize(:create, Department)
    end

    context "with valid params" do
      it "creates a new Department" do
        expect {
          post :create, {:department => valid_attributes}
        }.to change(Department, :count).by(1)
      end

      it "assigns a newly created department as @department" do
        post :create, {:department => valid_attributes}
        expect(assigns(:department)).to be_a(Department)
        expect(assigns(:department)).to be_persisted
      end

      it "redirects to the created department" do
        post :create, {:department => valid_attributes}
        expect(response).to redirect_to(Department.find_by(:code => "123456"))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved department as @department" do
        post :create, {:department => invalid_attributes}
        expect(assigns(:department)).to be_a_new(Department)
      end

      it "re-renders the 'new' template" do
        post :create, {:department => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before :each do
      should_authorize(:update, department)
    end
    context "with valid params" do
      let(:new_attributes) {
        {
          name: "New Name",
          code: "123456"
        }
      }

      it "updates the requested department" do
        put :update, {:id => department.id, :department => new_attributes}
        department.reload
        expect(department.name).to eq("New Name")
      end

      it "assigns the requested department as @department" do
        put :update, {:id => department.id, :department => valid_attributes}
        expect(assigns(:department)).to eq(department)
      end

      it "redirects to the department" do
        put :update, {:id => department.id, :department => valid_attributes}
        expect(response).to redirect_to(department)
      end
    end

    context "with invalid params" do
      it "assigns the department as @department" do
        put :update, {:id => department.id, :department => invalid_attributes}
        expect(assigns(:department)).to eq(department)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => department.id, :department => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before :each do
      should_authorize(:destroy, department)
    end

    it "destroys the requested department" do
      expect {
        delete :destroy, {:id => department.id}
      }.to change(Department, :count).by(-1)
    end

    it "redirects to the departments list" do
      delete :destroy, {:id => department.id}
      expect(response).to redirect_to(departments_url)
    end
  end

end
