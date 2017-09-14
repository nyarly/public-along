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

RSpec.describe SecurityProfilesController, type: :controller do

  let!(:security_profile) { FactoryGirl.create(:security_profile) }
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"]) }

  let(:valid_attributes) {
    {
      name: "this profile"
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
    it "assigns all security_profiles as @security_profiles" do
      should_authorize(:index, SecurityProfile)
      get :index
      expect(assigns(:security_profiles)).to eq([security_profile])
    end
  end

  describe "GET #show" do
    it "assigns the requested security_profile as @security_profile" do
      should_authorize(:show, security_profile)
      get :show, {:id => security_profile.id}
      expect(assigns(:security_profile)).to eq(security_profile)
    end
  end

  describe "GET #new" do
    it "assigns a new security_profile as @security_profile" do
      should_authorize(:new, SecurityProfile)
      get :new
      expect(assigns(:security_profile)).to be_a_new(SecurityProfile)
    end
  end

  describe "GET #edit" do
    it "assigns the requested security_profile as @security_profile" do
      should_authorize(:edit, security_profile)
      get :edit, {:id => security_profile.id}
      expect(assigns(:security_profile)).to eq(security_profile)
    end
  end

  describe "POST #create" do
    before :each do
      should_authorize(:create, SecurityProfile)
    end

    context "with valid params" do

      it "creates a new SecurityProfile" do
        expect {
          post :create, {:security_profile => valid_attributes}
        }.to change(SecurityProfile, :count).by(1)
      end

      it "assigns a newly created security_profile as @security_profile" do
        post :create, {:security_profile => valid_attributes}
        expect(assigns(:security_profile)).to be_a(SecurityProfile)
        expect(assigns(:security_profile)).to be_persisted
      end

      it "redirects to the created security_profile" do
        post :create, {:security_profile => valid_attributes}
        expect(response).to redirect_to(SecurityProfile.find_by(:name => "this profile"))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved security_profile as @security_profile" do
        post :create, {:security_profile => invalid_attributes}
        expect(assigns(:security_profile)).to be_a_new(SecurityProfile)
      end

      it "re-renders the 'new' template" do
        post :create, {:security_profile => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before :each do
      should_authorize(:update, security_profile)
    end

    context "with valid params" do
      let(:new_attributes) {
        {
          name: "new profile name"
        }
      }

      it "updates the requested security_profile" do
        put :update, {:id => security_profile.id, :security_profile => new_attributes}
        security_profile.reload
        expect(security_profile.name).to eq("new profile name")
      end

      it "assigns the requested security_profile as @security_profile" do
        put :update, {:id => security_profile.id, :security_profile => valid_attributes}
        expect(assigns(:security_profile)).to eq(security_profile)
      end

      it "redirects to the security_profile" do
        put :update, {:id => security_profile.id, :security_profile => valid_attributes}
        expect(response).to redirect_to(security_profile)
      end
    end

    context "with invalid params" do
      it "assigns the security_profile as @security_profile" do
        put :update, {:id => security_profile.id, :security_profile => invalid_attributes}
        expect(assigns(:security_profile)).to eq(security_profile)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => security_profile.id, :security_profile => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before :each do
      should_authorize(:destroy, security_profile)
    end

    it "destroys the requested security_profile" do
      expect {
        delete :destroy, {:id => security_profile.id}
      }.to change(SecurityProfile, :count).by(-1)
    end

    it "redirects to the security_profiles list" do
      delete :destroy, {:id => security_profile.id}
      expect(response).to redirect_to(security_profiles_url)
    end
  end

  describe "#app_access_levels" do
    before :each do
      should_authorize(:app_access_levels, SecurityProfile)
    end

    let!(:application) { FactoryGirl.create(:application)}
    let!(:access_level) { FactoryGirl.create(:access_level, application_id: application.id)}

    it "gets the access levels for an application" do
      @params = {:application_id => application.id, :format => 'js'}
      xhr :get, :app_access_levels, @params
      expect(response.status).to eq(200)
    end
  end

  describe "#sp_access_level" do
    before :each do
      should_authorize(:sp_access_level, SecurityProfile)
    end

    let!(:access_level) { FactoryGirl.create(:access_level)}

    it "gets the access levels selected" do
      @params = {:access_level_id => access_level.id, :format => 'js'}
      xhr :get, :sp_access_level, @params
      expect(response.status).to eq(200)
    end
  end
end
