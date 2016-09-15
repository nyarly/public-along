require 'rails_helper'

RSpec.describe EmployeesController, type: :controller do

  let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id) }
  let!(:manager) { FactoryGirl.create(:employee) }
  let!(:user) { FactoryGirl.create(:user, :role_name => "Admin", employee_id: manager.employee_id) }
  let!(:mailer) { double(ManagerMailer) }
  let!(:ads) { double(ActiveDirectoryService) }

  let(:valid_attributes) {
    {
      first_name: "Bob",
      last_name: "Barker",
      department_id: 1,
      location_id: 1,
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
        allow(ManagerMailer).to receive_message_chain(:permissions, :deliver_now)

        expect {
          post :create, {:employee => valid_attributes}
        }.to change(Employee, :count).by(1)
      end

      it "assigns a newly created employee as @employee" do
        allow(ManagerMailer).to receive_message_chain(:permissions, :deliver_now)

        post :create, {:employee => valid_attributes}
        expect(assigns(:employee)).to be_a(Employee)
        expect(assigns(:employee)).to be_persisted
      end

      it "sends a new employee to AD" do
        allow(ManagerMailer).to receive_message_chain(:permissions, :deliver_now)

        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:create_disabled_accounts)
        post :create, {:employee => valid_attributes}
      end

      it "sends an email to the manager" do
        expect(ManagerMailer).to receive_message_chain(:permissions, :deliver_now)

        post :create, {:employee => valid_attributes}
      end

      it "redirects to the created employee" do
        allow(ManagerMailer).to receive_message_chain(:permissions, :deliver_now)

        post :create, {:employee => valid_attributes}
        expect(response).to redirect_to(employees_url)
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
          first_name: "Bobby",
          last_name: "Barker",
          department_id: 1,
          location_id: 1
        }
      }

      it "updates the requested employee" do
        put :update, {:id => employee.id, :employee => new_attributes}
        employee.reload
        expect(employee.first_name).to eq("Bobby")
      end

      it "assigns the requested employee as @employee" do
        put :update, {:id => employee.id, :employee => valid_attributes}
        expect(assigns(:employee)).to eq(employee)
      end

      it "sends a updated employee to AD" do
        expect(ActiveDirectoryService).to receive(:new).and_return(ads)
        expect(ads).to receive(:update)

        put :update, {:id => employee.id, :employee => new_attributes}
      end

      it "redirects to the employee" do
        put :update, {:id => employee.id, :employee => valid_attributes}
        expect(response).to redirect_to(employees_url)
      end
    end

    context "business title change" do
      let(:new_attributes) {
        {
          business_title: "different business title"
        }
      }

      it "sends a security access email to manager" do
        expect(ManagerMailer).to receive(:permissions).with(manager, employee, "Security Access").and_return(mailer)
        expect(mailer).to receive(:deliver_now)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "manager id change" do
      let!(:new_manager) { FactoryGirl.create(:employee) }

      let(:new_attributes) {
        {
          manager_id: new_manager.employee_id
        }
      }

      it "sends a security access email to new manager" do
        expect(ManagerMailer).to receive(:permissions).with(new_manager, employee, "Security Access").and_return(mailer)
        expect(mailer).to receive(:deliver_now)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "rehire" do
      let(:new_attributes) {
        {
          hire_date: 2.weeks.from_now,
          termination_date: nil
        }
      }

      it "sends an onboarding email to manager" do
        employee.update_attributes(
          hire_date: 2.years.ago,
          termination_date: 1.year.ago
        )

        expect(ManagerMailer).to receive(:permissions).with(manager, employee, "Onboarding").and_return(mailer)
        expect(mailer).to receive(:deliver_now)

        put :update, {:id => employee.id, :employee => new_attributes}
      end
    end

    context "with invalid params" do
      it "assigns the employee as @employee" do
        put :update, {:id => employee.id, :employee => invalid_attributes}
        expect(assigns(:employee)).to eq(employee)
      end

      it "re-renders the 'edit' template" do
        put :update, {:id => employee.id, :employee => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

end
