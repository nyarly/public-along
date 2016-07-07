require 'rails_helper'

RSpec.describe "MachineBundles", type: :request do
  xdescribe "GET /machine_bundles" do
    it "works! (now write some real specs)" do
      get machine_bundles_path
      expect(response).to have_http_status(200)
    end
  end
end
