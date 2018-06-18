require 'rails_helper'

RSpec.describe EmployeesController, type: :controller do

  let(:manager) do
    FactoryGirl.create(:employee, :with_profile,
      first_name: 'Aaa',
      last_name: 'Aaa')
  end
  let(:employee)    { FactoryGirl.create(:employee, :with_profile, manager: manager) }
  let(:employee_2)  { FactoryGirl.create(:employee, manager: employee) }
  let(:sec_manager) { FactoryGirl.create(:employee) }
  let!(:employee_3) { FactoryGirl.create(:employee, manager: sec_manager) }
  let!(:employee_4) { FactoryGirl.create(:employee, manager: employee_3) }
  let(:dual_user) do
    FactoryGirl.create(:user,
      employee: sec_manager,
      role_names: %w[Manager Security])
  end
  let(:mgr_user) do
    FactoryGirl.create(:user,
      employee: manager,
      role_names: ['Manager'],
      adp_employee_id: manager.employee_id)
  end
  let(:user) do
    FactoryGirl.create(:user,
      employee: employee,
      role_names: ['Admin'],
      adp_employee_id: employee.employee_id)
  end

  describe 'GET #index' do
    context 'when admin' do
      before do
        login_as user
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'assigns all employees as @employees' do
        should_authorize(:index, Employee)
        get :index
        expect(assigns(:employees)).to include(sec_manager)
        expect(assigns(:employees)).to include(manager)
        expect(assigns(:employees)).to include(employee)
        expect(assigns(:employees)).to include(employee_3)
      end
    end

    context 'when manager' do
      before do
        login_as mgr_user
        allow(controller).to receive(:current_user).and_return(mgr_user)
      end

      it 'assigns only direct reports as @employees' do
        should_authorize(:index, Employee)
        get :index
        expect(assigns(:employees)).to include(employee)
        expect(assigns(:employees)).not_to include(sec_manager)
        expect(assigns(:employees)).not_to include(manager)
        expect(assigns(:employees)).not_to include(employee_3)
      end
    end

    context 'when manager/security dual role' do
      before do
        login_as dual_user
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'assigns all employees as @employees' do
        should_authorize(:index, Employee)
        get :index
        expect(assigns(:employees)).to include(sec_manager)
        expect(assigns(:employees)).to include(manager)
        expect(assigns(:employees)).to include(employee)
        expect(assigns(:employees)).to include(employee_3)
      end
    end
  end

  describe 'GET #show' do
    context 'when admin' do
      before do
        login_as user
      end

      it 'assigns the requested employee as @employee' do
        should_authorize(:show, employee)
        get :show, id: employee.id
        expect(assigns(:employee)).to eq(employee)
      end

      it 'assigns the requested employee as @employee' do
        should_authorize(:show, manager)
        get :show, id: manager.id
        expect(assigns(:employee)).to eq(manager)
      end

      it 'assigns the requested employee as @employee' do
        should_authorize(:show, employee_2)
        get :show, id: employee_2.id
        expect(assigns(:employee)).to eq(employee_2)
      end

      it 'assigns the requested employee as @employee' do
        should_authorize(:show, sec_manager)
        get :show, id: sec_manager.id
        expect(assigns(:employee)).to eq(sec_manager)
      end
    end

    context 'when manager' do
      before do
        login_as mgr_user
        request.env['HTTP_REFERER'] = 'where_i_came_from'
      end

      it 'assigns the requested employee as @employee' do
        get :show, id: employee.id
        expect(assigns(:employee)).to eq(employee)
      end

      it 'assigns the requested employee as @employee' do
        get :show, id: employee_2.id
        expect(assigns(:employee)).to eq(employee_2)
      end

      it 'assigns the requested employee as @employee' do
        get :show, id: employee_3.id
        expect(response).to redirect_to('http://test.hostwhere_i_came_from')
      end
    end

    context 'when security/manager' do
      before do
        login_as dual_user
      end

      it 'assigns the requested employee as @employee' do
        get :show, id: employee.id
        expect(assigns(:employee)).to eq(employee)
      end

      it 'assigns the requested employee as @employee' do
        get :show, id: employee_2.id
        expect(assigns(:employee)).to eq(employee_2)
      end

      it 'assigns the requested employee as @employee' do
        get :show, id: employee_3.id
        expect(assigns(:employee)).to eq(employee_3)
      end
    end
  end

  describe 'autocomplete search' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'searches for employees' do
      get :autocomplete_name, term: 'aa'
      expect(assigns(:employees)).to include(manager)
      expect(assigns(:employees)).not_to include(employee)
    end
  end

  describe 'GET employees/:id/#direct_reports' do
    before do
      request.env['HTTP_REFERER'] = 'where_i_came_from'
    end

    context 'when dual user' do
      before do
        login_as dual_user
      end

      it 'authorizes direct reports' do
        should_authorize(:direct_reports, employee_3)
        get :direct_reports, id: employee_3.id.to_s
        expect(response).to be_success
      end

      it 'authorizes indirect reports' do
        should_authorize(:direct_reports, employee_4)
        get :direct_reports, id: employee_4.id.to_s
        expect(response).to be_success
      end

      it 'authorizes other workers' do
        should_authorize(:direct_reports, manager)
        get :direct_reports, id: manager.id.to_s
        expect(response).to be_success
      end
    end

    context 'when manager' do
      before do
        login_as mgr_user
      end

      it 'authorizes direct reports' do
        should_authorize(:direct_reports, employee)
        get :direct_reports, id: employee.id.to_s
        expect(response).to be_success
      end

      it 'authorizes indirect reports' do
        should_authorize(:direct_reports, employee_2)
        get :direct_reports, id: employee_2.id.to_s
        expect(response).to be_success
      end

      it 'does not authorize other workers' do
        get :direct_reports, id: employee_4.id.to_s
        expect(response).to redirect_to('http://test.hostwhere_i_came_from')
      end
    end
  end
end
