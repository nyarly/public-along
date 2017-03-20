require 'rails_helper'

RSpec.describe OffboardCommandsController, type: :controller do
  
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"]) }
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:offboard_command) { FactoryGirl.create(:offboard_command, :employee_id => employee.id) }

  let(:valid_attributes) {
    {
      employee_id: employee.id
    }
  }

  before :each do
    login_as user
  end

  describe "GET #index" do
    it "assigns a new offboard_command as @offboard_command" do
      should_authorize(:index, OffboardCommand)
      get :index
      expect(assigns(:offboard_command)).to be_an_instance_of(OffboardCommand)
    end
  end

  describe "GET #new" do
    it "assigns a new offboard_command as @offboard_command" do
      should_authorize(:new, OffboardCommand)
      get :new
      expect(assigns(:offboard_command)).to be_an_instance_of(OffboardCommand)
    end
  end

  describe "POST #create" do
    it "assigns a new offboard_command as @offboard_command" do
      should_authorize(:create, OffboardCommand)
      post :create, {:offboard_command => valid_attributes }
      expect(assigns(:offboard_command)).to be_an_instance_of(OffboardCommand)
    end

    it "renders the index template" do
      should_authorize(:create, OffboardCommand)
      post :create, {:offboard_command => valid_attributes }
      expect(response).to render_template("index")
    end
  end

end