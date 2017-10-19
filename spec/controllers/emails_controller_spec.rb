require 'rails_helper'

RSpec.describe EmailsController, type: :controller do
  let(:user)     { FactoryGirl.create(:user, :role_names => ["Admin"]) }
  # let(:manager)  { FactoryGirl.create(:employee, :with_profile, email: "somethingelse@example.com") }
  let(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager, email: "something@example.com") }

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
