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

RSpec.describe MachineBundlesController, type: :controller do

  let!(:machine_bundle) { FactoryGirl.create(:machine_bundle) }
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"]) }

  let(:valid_attributes) {
    {
      name: "Machine Bundle",
      description: "description of Machine Bundle"
    }
  }

  let(:invalid_attributes) {
    {
      name: nil,
      description: "something"
    }
  }

  before :each do
    login_as user
  end

  describe "GET #index" do
    it "assigns all machine_bundles as @machine_bundles" do
      should_authorize(:index, MachineBundle)
      get :index
      expect(assigns(:machine_bundles)).to include(machine_bundle)
    end
  end

  describe "GET #show" do
    it "assigns the requested machine_bundle as @machine_bundle" do
      should_authorize(:show, machine_bundle)
      get :show, {:id => machine_bundle.id}
      expect(assigns(:machine_bundle)).to eq(machine_bundle)
    end
  end

  describe "GET #new" do
    it "assigns a new machine_bundle as @machine_bundle" do
      should_authorize(:new, MachineBundle)
      get :new
      expect(assigns(:machine_bundle)).to be_a_new(MachineBundle)
    end
  end

  describe "GET #edit" do
    it "assigns the requested machine_bundle as @machine_bundle" do
      should_authorize(:edit, machine_bundle)
      get :edit, {:id => machine_bundle.id}
      expect(assigns(:machine_bundle)).to eq(machine_bundle)
    end
  end

  describe "POST #create" do
    before :each do
      should_authorize(:create, MachineBundle)
    end

    context "with valid params" do
      it "creates a new MachineBundle" do
        expect {
          post :create, {:machine_bundle => valid_attributes}
        }.to change(MachineBundle, :count).by(1)
      end

      it "assigns a newly created machine_bundle as @machine_bundle" do
        post :create, {:machine_bundle => valid_attributes}
        expect(assigns(:machine_bundle)).to be_a(MachineBundle)
        expect(assigns(:machine_bundle)).to be_persisted
      end

      it "redirects to the created machine_bundle" do
        post :create, {:machine_bundle => valid_attributes}
        expect(response).to redirect_to(MachineBundle.find_by(:name => "Machine Bundle"))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved machine_bundle as @machine_bundle" do
        post :create, {:machine_bundle => invalid_attributes}
        expect(assigns(:machine_bundle)).to be_a_new(MachineBundle)
      end

      it "re-renders the 'new' template" do
        post :create, {:machine_bundle => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before :each do
      should_authorize(:update, machine_bundle)
    end

    context "with valid params" do
      let(:new_attributes) {
        {
          name: "Machine Bundle",
          description: "new description of Machine Bundle"
        }
      }

      it "updates the requested machine_bundle" do
        put :update, {:id => machine_bundle.id, :machine_bundle => new_attributes}
        machine_bundle.reload
        expect(machine_bundle.description).to eq("new description of Machine Bundle")
      end

      it "assigns the requested machine_bundle as @machine_bundle" do
        put :update, {:id => machine_bundle.id, :machine_bundle => valid_attributes}
        expect(assigns(:machine_bundle)).to eq(machine_bundle)
      end

      it "redirects to the machine_bundle" do
        put :update, {:id => machine_bundle.id, :machine_bundle => valid_attributes}
        expect(response).to redirect_to(machine_bundle)
      end
    end

    context "with invalid params" do
      it "assigns the machine_bundle as @machine_bundle" do
        put :update, {:id => machine_bundle.id, :machine_bundle => invalid_attributes}
        expect(assigns(:machine_bundle)).to eq(machine_bundle)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => machine_bundle.id, :machine_bundle => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    before :each do
      should_authorize(:destroy, machine_bundle)
    end

    it "destroys the requested machine_bundle" do
      expect {
        delete :destroy, {:id => machine_bundle.id}
      }.to change(MachineBundle, :count).by(-1)
    end

    it "redirects to the machine_bundles list" do
      delete :destroy, {:id => machine_bundle.id}
      expect(response).to redirect_to(machine_bundles_url)
    end
  end

end
