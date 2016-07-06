require 'rails_helper'

RSpec.describe "Departments", type: :request do
  xdescribe "GET /departments" do
    let!(:user) { FactoryGirl.create(:user, :role_name => "Admin") }

    before :each do
      login_as user
    end

    it "should succeed" do
      should_authorize(:index, Department)
      get departments_path
      expect(response).to have_http_status(200)
    end
  end
end
