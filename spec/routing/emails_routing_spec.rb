require "rails_helper"

RSpec.describe EmailsController, type: :routing do
  describe "routing" do

    it "routes to #create" do
      expect(:post => "/emails").to route_to("emails#create")
    end
  end
end