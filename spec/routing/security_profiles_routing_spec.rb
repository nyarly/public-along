require "rails_helper"

RSpec.describe SecurityProfilesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/security_profiles").to route_to("security_profiles#index")
    end

    it "routes to #new" do
      expect(:get => "/security_profiles/new").to route_to("security_profiles#new")
    end

    it "routes to #show" do
      expect(:get => "/security_profiles/1").to route_to("security_profiles#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/security_profiles/1/edit").to route_to("security_profiles#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/security_profiles").to route_to("security_profiles#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/security_profiles/1").to route_to("security_profiles#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/security_profiles/1").to route_to("security_profiles#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/security_profiles/1").to route_to("security_profiles#destroy", :id => "1")
    end

    it "routes #update_al_opts" do
      expect(:get => "/update_al_opts").to route_to("security_profiles#update_al_opts")
    end

    it "routes #update_al_ids" do
      expect(:get => "/update_al_ids").to route_to("security_profiles#update_al_ids")
    end

    it "routes #remove_al_id" do
      expect(:get => "/remove_al_id").to route_to("security_profiles#remove_al_id")
    end
  end
end
