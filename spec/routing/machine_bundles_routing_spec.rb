require "rails_helper"

RSpec.describe MachineBundlesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/machine_bundles").to route_to("machine_bundles#index")
    end

    it "routes to #new" do
      expect(:get => "/machine_bundles/new").to route_to("machine_bundles#new")
    end

    it "routes to #show" do
      expect(:get => "/machine_bundles/1").to route_to("machine_bundles#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/machine_bundles/1/edit").to route_to("machine_bundles#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/machine_bundles").to route_to("machine_bundles#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/machine_bundles/1").to route_to("machine_bundles#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/machine_bundles/1").to route_to("machine_bundles#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/machine_bundles/1").to route_to("machine_bundles#destroy", :id => "1")
    end

  end
end
