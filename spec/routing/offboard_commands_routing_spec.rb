require "rails_helper"

RSpec.describe OffboardCommandsController, type: :routing do
  describe "routing" do

    it "routes to #generate" do
      expect(:get => "/offboard_commands").to route_to("offboard_commands#generate")
    end
  end
end
