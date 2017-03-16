require "rails_helper"

RSpec.describe OffboardCommandsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/offboard_commands").to route_to("offboard_commands#index")
    end

    it "routes to #new" do
      expect(:get => "/offboard_commands/new").to route_to("offboard_commands#new")
    end

    it "routes to #show" do
      expect(:get => "/offboard_commands/1").to route_to("offboard_commands#show", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/offboard_commands").to route_to("offboard_commands#create")
    end

  end
end
