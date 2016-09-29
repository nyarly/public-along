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

RSpec.describe ApplicationsController, type: :controller do

  let!(:application) { FactoryGirl.create(:application) }
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"]) }

  let(:valid_attributes) {
    {
      name: "this app"
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
    it "assigns all applications as @applications" do
      should_authorize(:index, Application)
      get :index
      expect(assigns(:applications)).to eq([application])
    end
  end

  describe "GET #show" do
    it "assigns the requested application as @application" do
      should_authorize(:show, application)
      get :show, {:id => application.id}
      expect(assigns(:application)).to eq(application)
    end
  end

  describe "GET #new" do
    it "assigns a new application as @application" do
      should_authorize(:new, Application)
      get :new
      expect(assigns(:application)).to be_a_new(Application)
    end
  end

  describe "GET #edit" do
    it "assigns the requested application as @application" do
      should_authorize(:edit, application)
      get :edit, {:id => application.id}
      expect(assigns(:application)).to eq(application)
    end
  end

  describe "POST #create" do
    before :each do
      should_authorize(:create, Application)
    end

    context "with valid params" do
      it "creates a new Application" do
        expect {
          post :create, {:application => valid_attributes}
        }.to change(Application, :count).by(1)
      end

      it "assigns a newly created application as @application" do
        post :create, {:application => valid_attributes}
        expect(assigns(:application)).to be_a(Application)
        expect(assigns(:application)).to be_persisted
      end

      it "redirects to the created application" do
        post :create, {:application => valid_attributes}
        expect(response).to redirect_to(Application.find_by(:name => "this app"))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved application as @application" do
        post :create, {:application => invalid_attributes}
        expect(assigns(:application)).to be_a_new(Application)
      end

      it "re-renders the 'new' template" do
        post :create, {:application => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before :each do
      should_authorize(:update, application)
    end

    context "with valid params" do
      let(:new_attributes) {
        {
          name: "new app name"
        }
      }

      it "updates the requested application" do
        put :update, {:id => application.id, :application => new_attributes}
        application.reload
        expect(application.name).to eq("new app name")
      end

      it "assigns the requested application as @application" do
        put :update, {:id => application.id, :application => valid_attributes}
        expect(assigns(:application)).to eq(application)
      end

      it "redirects to the application" do
        put :update, {:id => application.id, :application => valid_attributes}
        expect(response).to redirect_to(application)
      end
    end

    context "with invalid params" do
      it "assigns the application as @application" do
        put :update, {:id => application.id, :application => invalid_attributes}
        expect(assigns(:application)).to eq(application)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => application.id, :application => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before :each do
      should_authorize(:destroy, application)
    end

    it "destroys the requested application" do
      expect {
        delete :destroy, {:id => application.id}
      }.to change(Application, :count).by(-1)
    end

    it "redirects to the applications list" do
      delete :destroy, {:id => application.id}
      expect(response).to redirect_to(applications_url)
    end
  end

end
