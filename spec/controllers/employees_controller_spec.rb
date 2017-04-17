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

  describe "GET #new" do
    it "assigns a new employee as @employee" do
      should_authorize(:new, Employee)
      get :new
      expect(assigns(:employee)).to be_a_new(Employee)
    end
  end

  describe "GET #edit" do
    it "assigns the requested employee as @employee" do
      should_authorize(:edit, employee)
      get :edit, {:id => employee.id}
      expect(assigns(:employee)).to eq(employee)
    end
  end

  describe "POST #create" do
    before :each do
      should_authorize(:create, Employee)
    end

    context "with valid params" do
      it "creates a new employee" do
        expect {
          post :create, {:employee => valid_attributes}
        }.to change(Employee, :count).by(1)
      end

      it "assigns a newly created employee as @employee" do
        post :create, {:employee => valid_attributes}
        expect(assigns(:employee)).to be_a(Employee)
        expect(assigns(:employee)).to be_persisted
      end

      it "sends a new employee to AD" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        expect(ads).to receive(:errors).and_return({})

        post :create, {:employee => valid_attributes}
      end

      it "redirects to the created employee" do
        allow(ActiveDirectoryService).to receive(:new).and_return(ads)
        allow(ads).to receive(:create_disabled_accounts)
        allow(ads).to receive(:errors).and_return({})

        post :create, {:employee => valid_attributes}
        expect(response).to redirect_to(employee_url(Employee.find_by(last_name: "Barker").id))
      end
    end

    context "with valid params and failed account creation" do
      it "redirects to employee edit" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        allow(ads).to receive(:errors).and_return({ad: "errors"})

        post :create, {:employee => valid_attributes}
        expect(response).to redirect_to(edit_employee_url(Employee.find_by(last_name: "Barker").id))
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved employee as @employee" do
        post :create, {:employee => invalid_attributes}
        expect(assigns(:employee)).to be_a_new(Employee)
      end

      it "should not send an email to the manager" do
        expect(ManagerMailer).to_not receive(:permissions)

        post :create, {:employee => invalid_attributes}
      end

      it "re-renders the 'new' template" do
        post :create, {:employee => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    before :each do
      should_authorize(:update, employee)
    end

    context "with valid params" do
      let(:new_attributes) {
        {
          first_name: "Al",
          location_id: 1,
          department_id: 1,
          ad_updated_at: DateTime.new(2016, 12, 1)
        }
      }

      it "updates the requested employee" do
        put :update, {:id => employee.id, :employee => new_attributes}
        employee.reload
        expect(employee.first_name).to eq("Al")
      end

      it "assigns the requested employee as @employee" do
        put :update, {:id => employee.id, :employee => new_attributes}
        expect(assigns(:employee)).to eq(employee)
      end

      it "records attribute changes" do
        put :update, {:id => employee.id, :employee => new_attributes}
        expect(EmpDelta.last.employee_id).to eq(employee.id)
        expect(EmpDelta.last.before).to eq(
          {
            "first_name"=>"Alex",
            "location_id"=>employee.location.id.to_s,
            "department_id"=>employee.department.id.to_s,
            "ad_updated_at"=>nil
          })
        expect(EmpDelta.last.after).to eq(
          {
            "first_name" => "Al",
            "location_id" => "1",
            "department_id" => "1",
            "ad_updated_at" => "2016-12-01 00:00:00 UTC"
          })
      end

      it "sends a updated employee to AD" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)
        expect(ads).to receive(:errors).and_return({})

        put :update, {:id => employee.id, :employee => new_attributes}
      end

      it "redirects to the employee" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)
        expect(ads).to receive(:errors).and_return({})

        put :update, {:id => employee.id, :employee => new_attributes}
        expect(response).to redirect_to(employee_url(employee))
      end
    end

    context "with valid params for an account not created in AD" do
      let(:new_attributes) {
        {
          first_name: "Al",
          department_id: 1,
          location_id: 1,
          ad_updated_at: nil
        }
      }

      it "updates the requested employee" do
        put :update, {:id => employee.id, :employee => new_attributes}
        employee.reload
        expect(employee.first_name).to eq("Al")
      end

      it "assigns the requested employee as @employee" do
        put :update, {:id => employee.id, :employee => new_attributes}
        expect(assigns(:employee)).to eq(employee)
      end

      it "creates employee to AD" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        allow(ads).to receive(:errors)

        put :update, {:id => employee.id, :employee => new_attributes}
      end

      it "redirects to the employee if there are no errors" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        allow(ads).to receive(:errors).and_return({})

        put :update, {:id => employee.id, :employee => new_attributes}
        expect(response).to redirect_to(employee_url(employee))
      end

      it "redirects to edit employee if there are errors" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        allow(ads).to receive(:errors).and_return({active_directory: "errors"})

        put :update, {:id => employee.id, :employee => new_attributes}
        expect(response).to redirect_to(edit_employee_url(employee))
      end
    end

    context "Job Change - Department id" do
      let(:new_attributes) {
        {
          first_name: "Bobby",
          last_name: "Barker",
          department_id: 777,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).to receive(:perform_async).with("Security Access", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "Job Change - Location id" do
      let(:new_attributes) {
        {
          first_name: "Bobby",
          last_name: "Barker",
          location_id: 333,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).to receive(:perform_async).with("Security Access", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "Job Change - Worker Type id" do
      let(:new_attributes) {
        {
          first_name: "Bobby",
          last_name: "Barker",
          worker_type_id: 2,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).to receive(:perform_async).with("Security Access", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "Job Change - Job Title id" do
      let(:new_attributes) {
        {
          first_name: "Bobby",
          last_name: "Barker",
          job_title_id: 666,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).to receive(:perform_async).with("Security Access", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "No changes requiring Security Access form review" do
      let(:new_attributes) {
        {
          first_name: "Bobby",
          last_name: "Barker",
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).not_to receive(:perform_async).with("Security Access", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "Rehire" do
      let(:new_attributes) {
        {
          hire_date: 2.weeks.from_now,
          termination_date: nil,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        employee.hire_date = 4.years.ago
        employee.termination_date = 3.years.ago
        employee.save!

        expect(EmployeeWorker).to receive(:perform_async).with("Onboarding", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "Termination" do
      let(:zeroed_date) { 14.days.from_now.change(:usec => 0) }

      let(:new_attributes) {
        {
          termination_date: zeroed_date,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).to receive(:perform_at).with(5.business_days.before(zeroed_date),"Offboarding", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "Termination - expedited" do
      let(:new_attributes) {
        {
          termination_date: 2.days.from_now,
          ad_updated_at: 10.months.ago
        }
      }

      it "calls EmployeeWorker with correct values" do
        expect(EmployeeWorker).to receive(:perform_async).with("Offboarding", employee.id)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "no change to attributes" do
      let(:new_attributes) {
        {
          first_name: employee.first_name,
          ad_updated_at: 10.months.ago
        }
      }

      it "should not call EmployeeWorker" do
        expect(EmployeeWorker).to_not receive(:perform_async)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "with invalid params" do
      it "assigns the employee as @employee" do
        put :update, {:id => employee.id, :employee => invalid_attributes}
        expect(assigns(:employee)).to eq(employee)
      end

      it "should not call EmployeeWorker" do
        expect(EmployeeWorker).to_not receive(:perform_async)

        put :update, {:id => employee.id, :employee => invalid_attributes}
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => employee.id, :employee => invalid_attributes}
        expect(response).to render_template("edit")
      end
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
