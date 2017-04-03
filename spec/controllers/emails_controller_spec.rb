require 'rails_helper'

RSpec.describe EmailsController, type: :controller do

  let(:user) { FactoryGirl.create(:user, :role_names => ["Admin"])}
  let(:valid_attributes) do
    {
      employee_id: "TechTableMailer",
      email_kind: "Security Access",
      send_at: "Now"
    }
  end

  before :each do
    login_as user
  end

  describe "POST #create" do
    it "creates a new email" do
      should_authorize(:create, Email)
      post :create, { :email => valid_attributes }
      expect(response.status).to eq(200)
      expect(assigns(:email)).to be_an_instance_of(Email)
    end

  end
end