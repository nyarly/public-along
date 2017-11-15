require 'rails_helper'

RSpec.describe EmployeesController, type: :controller do

  let(:manager) { FactoryGirl.create(:employee, :with_profile,
    first_name: "Pat",
    last_name: "Sajak") }
  let(:employee) { FactoryGirl.create(:employee, :with_profile,
    first_name: "Alex",
    last_name: "Trebek",
    manager: manager) }
  let(:user) { FactoryGirl.create(:user,
    employee: employee,
    role_names: ["Admin"],
    adp_employee_id: employee.employee_id) }
  let(:mgr_user) { FactoryGirl.create(:user,
    employee: manager,
    role_names: ["Manager"],
    adp_employee_id: manager.employee_id) }

  before :each do
    login_as user
  end

  describe "GET #index" do
    it "assigns all employees as @employees" do
      allow(controller).to receive(:current_user).and_return(user)
      should_authorize(:index, Employee)
      get :index
      expect(assigns(:employees)).to include(employee)
    end

    it "finds the correct employees with search params" do
      allow(controller).to receive(:current_user).and_return(user)
      should_authorize(:index, Employee)
      get :index, { search: "pa" }
      expect(assigns(:employees)).to include(manager)
      expect(assigns(:employees)).to_not include(employee)
    end

    it "only shows direct reports for managers" do
      allow(controller).to receive(:current_user).and_return(mgr_user)
      should_authorize(:index, Employee)
      get :index
      expect(assigns(:employees)).to include(employee)
    end
  end

  describe "GET #show" do
    it "assigns the requested employee as @employee" do
      should_authorize(:show, employee)
      get :show, {:id => employee.id}
      expect(assigns(:employee)).to eq(employee)
    end
  end

  describe "autocomplete search" do
    it "searches for employees" do
      allow(controller).to receive(:current_user).and_return(user)
      get :autocomplete_name, {:term => 'al'}
      expect(assigns(:employees)).to include(employee)
      expect(assigns(:employees)).to_not include(manager)
    end
  end


  describe "GET employees/:id/#direct_reports" do
    let(:manager_employee) { FactoryGirl.create(:regular_employee) }
    let(:manager_user)     { FactoryGirl.create(:user, role_names: ["Manager"], employee: manager_employee) }

    let(:hr_manager_employee) { FactoryGirl.create(:regular_employee) }
    let(:hr_manager_user) { FactoryGirl.create(:user, role_names: ["HumanResources", "Manager"], employee: hr_manager_employee) }
    let(:hr_report) { FactoryGirl.create(:regular_employee, manager: hr_manager_employee) }
    let(:hr_indirect_report) { FactoryGirl.create(:regular_employee, manager: hr_report) }

    before :each do
      request.env["HTTP_REFERER"] = "where_i_came_from"
    end

    it "authorizes direct reports" do
      sign_in hr_manager_user
      get :direct_reports, {:id => "#{hr_report.id}"}
      expect(response).to be_success
    end

    it "authorizes indirect reports" do
      sign_in hr_manager_user
      get :direct_reports, {:id => "#{hr_indirect_report.id}"}
      expect(response).to be_success
    end

    it "does not authorize other direct reports" do
      sign_in manager_user
      get :direct_reports, {:id => "#{hr_indirect_report.id}"}
      expect(response).to redirect_to("http://test.hostwhere_i_came_from")
    end
  end
end
