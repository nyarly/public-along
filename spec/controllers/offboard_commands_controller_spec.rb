require 'rails_helper'

RSpec.describe OffboardCommandsController, type: :controller do
  
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"]) }
  let!(:employee) { FactoryGirl.create(:employee) }

  before :each do
    login_as user
  end

  describe "GET #generate" do
    it "assigns a new offboard_command as @offboard_command" do
      should_authorize(:generate, OffboardCommand)
      get :generate, employee_id: employee.employee_id
      expect(assigns(:offboard_command)).to be_an_instance_of(OffboardCommand)
    end
  end
end