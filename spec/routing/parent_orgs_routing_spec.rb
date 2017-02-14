require "rails_helper"

RSpec.describe ParentOrgsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/parent_orgs").to route_to("parent_orgs#index")
    end

    it "routes to #new" do
      expect(:get => "/parent_orgs/new").to route_to("parent_orgs#new")
    end

    it "routes to #show" do
      expect(:get => "/parent_orgs/1").to route_to("parent_orgs#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/parent_orgs/1/edit").to route_to("parent_orgs#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/parent_orgs").to route_to("parent_orgs#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/parent_orgs/1").to route_to("parent_orgs#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/parent_orgs/1").to route_to("parent_orgs#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/parent_orgs/1").to route_to("parent_orgs#destroy", :id => "1")
    end

  end
end
