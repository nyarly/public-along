require 'rails_helper'

RSpec.describe EmployeesController, type: :controller do

  let!(:employee) { FactoryGirl.create(:employee, first_name: "Alex", last_name: "Trebek", manager_id: manager.employee_id, worker_type_id: worker_type.id, job_title_id: job_title.id) }
  let!(:job_title) { FactoryGirl.create(:job_title, id: 444) }
  let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Regular") }
  let!(:manager) { FactoryGirl.create(:employee, first_name: "Pat", last_name: "Sajak") }
  let!(:user) { FactoryGirl.create(:user, :role_names => ["Admin"], employee_id: employee.employee_id) }
  let!(:mgr_user) { FactoryGirl.create(:user, :role_names => ["Manager"], employee_id: manager.employee_id) }
  let!(:mailer) { double(ManagerMailer) }
  let!(:ads) { double(ActiveDirectoryService) }

  let(:valid_attributes) {
    {
      first_name: "Bob",
      last_name: "Barker",
      department_id: 1,
      location_id: 1,
      worker_type_id: worker_type.id,
      hire_date: 1.week.from_now
    }
  }

  let(:invalid_attributes) {
    {
      first_name: nil,
      last_name: "Barker",
      department_id: 1,
      location_id: 1
    }
  }

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

end
