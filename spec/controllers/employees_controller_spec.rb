require 'rails_helper'

RSpec.describe EmployeesController, type: :controller do

  let(:manager)     { FactoryGirl.create(:employee, :with_profile,
                      first_name: "Aaa",
                      last_name: "Aaa") }
  let(:employee)    { FactoryGirl.create(:employee, :with_profile,
                      first_name: "Bbb",
                      last_name: "Bbb",
                      manager: manager) }
  let(:employee_2)  { FactoryGirl.create(:employee,
                      first_name: "Ccc",
                      last_name: "Ccc",
                      manager: employee) }
  let(:sec_manager) { FactoryGirl.create(:employee,
                      first_name: "Ddd",
                      last_name: "Ddd") }
  let!(:employee_3) { FactoryGirl.create(:employee,
                      manager: sec_manager) }
  let!(:employee_4) { FactoryGirl.create(:employee,
                      manager: employee_3) }
  let(:dual_user)   { FactoryGirl.create(:user,
                      employee: sec_manager,
                      role_names: ["Manager", "Security"]) }
  let(:mgr_user)    { FactoryGirl.create(:user,
                      employee: manager,
                      role_names: ["Manager"],
                      adp_employee_id: manager.employee_id) }
  let(:user)        { FactoryGirl.create(:user,
                      employee: employee,
                      role_names: ["Admin"],
                      adp_employee_id: employee.employee_id) }

  describe "GET #index" do
    context "as an admin" do
      before :each do
        login_as user
      end

      it "assigns all employees as @employees" do
        allow(controller).to receive(:current_user).and_return(user)
        should_authorize(:index, Employee)
        get :index
        expect(assigns(:employees)).to include(sec_manager)
        expect(assigns(:employees)).to include(manager)
        expect(assigns(:employees)).to include(employee)
        expect(assigns(:employees)).to include(employee_3)
      end
    end

    context "as a manager" do
      before :each do
        login_as mgr_user
      end

      it "assigns only direct reports as @employees" do
        allow(controller).to receive(:current_user).and_return(mgr_user)
        should_authorize(:index, Employee)
        get :index
        expect(assigns(:employees)).to include(employee)
        expect(assigns(:employees)).not_to include(sec_manager)
        expect(assigns(:employees)).not_to include(manager)
        expect(assigns(:employees)).not_to include(employee_3)
      end
    end

    context "as a manager/security dual role" do
      before :each do
        login_as dual_user
      end

      it "assigns all employees as @employees" do
        allow(controller).to receive(:current_user).and_return(user)
        should_authorize(:index, Employee)
        get :index
        expect(assigns(:employees)).to include(sec_manager)
        expect(assigns(:employees)).to include(manager)
        expect(assigns(:employees)).to include(employee)
        expect(assigns(:employees)).to include(employee_3)
      end
    end
  end

  describe "GET #show" do
    context "as an admin" do
      before :each do
        login_as user
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, employee)
        get :show, { id: employee.id }
        expect(assigns(:employee)).to eq(employee)
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, manager)
        get :show, { id: manager.id }
        expect(assigns(:employee)).to eq(manager)
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, sec_manager)
        get :show, { id: sec_manager.id }
        expect(assigns(:employee)).to eq(sec_manager)
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, employee_3)
        get :show, { id: employee_3.id }
        expect(assigns(:employee)).to eq(employee_3)
      end
    end

    context "as a manager" do
      before :each do
        login_as mgr_user
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, employee)
        get :show, { id: employee.id }
        expect(assigns(:employee)).to eq(employee)
      end

      it "does not assign the requested employee as @employee" do
        should_authorize(:show, manager)
        get :show, { id: manager.id }
        expect(assigns(:employee)).to eq(nil)
      end

      it "does not assign the requested employee as @employee" do
        should_authorize(:show, sec_manager)
        get :show, { id: sec_manager.id }
        expect(assigns(:employee)).to eq(nil)
      end

      it "does not assign the requested employee as @employee" do
        should_authorize(:show, employee_3)
        get :show, { id: employee_3.id }
        expect(assigns(:employee)).to eq(nil)
      end
    end

    context "as a security/manager" do
      before :each do
        login_as dual_user
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, employee)
        get :show, { id: employee.id }
        expect(assigns(:employee)).to eq(employee)
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, manager)
        get :show, { id: manager.id }
        expect(assigns(:employee)).to eq(manager)
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, sec_manager)
        get :show, { id: sec_manager.id }
        expect(assigns(:employee)).to eq(sec_manager)
      end

      it "assigns the requested employee as @employee" do
        should_authorize(:show, employee_3)
        get :show, { id: employee_3.id }
        expect(assigns(:employee)).to eq(employee_3)
      end
    end
  end

  describe "autocomplete search" do
    it "searches for employees" do
      allow(controller).to receive(:current_user).and_return(user)
      get :autocomplete_name, {:term => 'aa'}
      expect(assigns(:employees)).to include(manager)
      expect(assigns(:employees)).to_not include(employee)
    end
  end


  describe "GET employees/:id/#direct_reports" do
    before :each do
      request.env["HTTP_REFERER"] = "where_i_came_from"
    end

    context "dual user" do
      before :each do
        login_as dual_user
      end

      it "authorizes direct reports" do
        get :direct_reports, {:id => "#{employee_3.id}"}
        expect(response).to be_success
      end

      it "authorizes indirect reports" do
        get :direct_reports, {:id => "#{employee_4.id}"}
        expect(response).to be_success
      end
    end

    context "manager" do
      before :each do
        login_as mgr_user
      end

      it "authorizes direct reports" do
        get :direct_reports, {:id => "#{employee.id}"}
        expect(response).to be_success
      end

      it "authorizes indirect reports" do
        get :direct_reports, {:id => "#{employee_2.id}"}
        expect(response).to be_success
      end

      it "does not authorize other workers" do
        get :direct_reports, {:id => "#{employee_4.id}"}
        expect(response).to redirect_to("http://test.hostwhere_i_came_from")
      end
    end

  end
end
