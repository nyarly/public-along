require "rails_helper"

RSpec.describe EmpTransactionsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/emp_transactions").to route_to("emp_transactions#index")
    end

    it "routes to #new" do
      expect(:get => "/emp_transactions/new").to route_to("emp_transactions#new")
    end

    it "routes to #show" do
      expect(:get => "/emp_transactions/1").to route_to("emp_transactions#show", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/emp_transactions").to route_to("emp_transactions#create")
    end

  end
end
