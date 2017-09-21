require 'rails_helper'

RSpec.describe EmailsController, type: :controller do
  let(:user)     { FactoryGirl.create(:user, :role_names => ["Admin"])}
  let(:manager)  { FactoryGirl.create(:regular_employee, email: "something@example.com")}
  let(:employee) { FactoryGirl.create(:active_employee)}
  let!(:profile) { FactoryGirl.create(:active_profile,
                   employee: employee,
                   manager_id: manager.employee_id)}

  let(:valid_attributes) do
    {
      employee_id: employee.id,
      email_option: "Security Access"
    }
  end

  before :each do
    login_as user
  end

  describe "POST #create" do
    it "creates a new email" do
      should_authorize(:create, Email)
      post :create, { :email => valid_attributes }
      expect(response.status).to eq(302)
      expect(assigns(:email)).to be_an_instance_of(Email)
    end
  end
end
