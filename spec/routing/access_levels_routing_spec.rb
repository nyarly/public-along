require "rails_helper"

RSpec.describe AccessLevelsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/access_levels").to route_to("access_levels#index")
    end

    it "routes to #new" do
      expect(:get => "/access_levels/new").to route_to("access_levels#new")
    end

    it "routes to #show" do
      expect(:get => "/access_levels/1").to route_to("access_levels#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/access_levels/1/edit").to route_to("access_levels#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/access_levels").to route_to("access_levels#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/access_levels/1").to route_to("access_levels#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/access_levels/1").to route_to("access_levels#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/access_levels/1").to route_to("access_levels#destroy", :id => "1")
    end

  end
end
