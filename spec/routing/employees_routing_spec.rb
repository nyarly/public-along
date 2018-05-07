require "rails_helper"

RSpec.describe EmployeesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/employees").to route_to("employees#index")
    end

    it "routes to #show" do
      expect(:get => "/employees/1").to route_to("employees#show", :id => "1")
    end

    it "routes to #autocomplete_name" do
      expect(:get => "employees/autocomplete_name?term=something").to route_to("employees#autocomplete_name", :term => "something")
    end

    it "routes to #direct_reports" do
      expect(:get => "employees/1/direct_reports").to route_to("employees#direct_reports", :id => "1")
    end

    it 'routes to #new_hires' do
      expect(get: 'employees/new_hires').to route_to('employees/new_hires#index')
    end

    it 'routes to #inactives' do
      expect(get: 'employees/inactives').to route_to('employees/inactives#index')
    end

    it 'routes to #offboards' do
      expect(get: 'employees/offboards').to route_to('employees/offboards#index')
    end
  end
end
