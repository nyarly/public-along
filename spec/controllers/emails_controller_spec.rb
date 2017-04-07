require 'rails_helper'

RSpec.describe EmailsController, type: :controller do
  let(:user) { FactoryGirl.create(:user, :role_names => ["Admin"])}
  let(:manager) { FactoryGirl.create(:employee, :employee_id => "223344", :email => "xyz@otcorptest.com")}
  let(:employee) { FactoryGirl.create(:employee, :id => "112233", :manager_id => manager.employee_id)}
  let(:valid_attributes) do
    {
      employee_id: employee.id,
      email_kind: "Security Access"
    }
  end

  before :each do
    login_as user
  end

  describe "POST #create" do
    it "creates a new email but render nothing" do
      should_authorize(:create, Email)
      post :create, { :email => valid_attributes }
      expect(response.status).to eq(200)
      expect(response.body).to eq('')
      expect(assigns(:email)).to be_an_instance_of(Email)
    end
  end
end