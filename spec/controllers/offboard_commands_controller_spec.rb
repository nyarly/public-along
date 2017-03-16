require 'rails_helper'

RSpec.describe OffboardCommandsController, type: :controller do
  
  let!(:offboard_command) { FactoryGirl.create(:offboard_command) }
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Helpdesk"]) }
  let!(:manager) { FactoryGirl.create(:employee) }
  let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }

  let(:valid_attributes) {
    {
      employee_id: employee.id
    }
  }

  let(:invalid_attributes) {
    {
      employee_id: nil
    }
  }

  before :each do
    login_as user
  end

  describe "GET #index" do
    it "assigns a new offboard_command as @offboard_command" do
      should_authorize(:new, OffboardCommand)
      should_authorize(:index, Employee)
      get :index
      expect(assigns(:offboard_command)).to be_a_new(OffboardCommand)
    end

    it "assigns all employees as @employees" do
      should_authorize(:index, Employee)
      get :index
      expect(assigns(:employees)).to eq([employees])
    end
  end




end