require 'rails_helper'

RSpec.describe Employees::InactivesController, type: :controller do
  describe 'GET #index' do
    let(:user) { FactoryGirl.create(:user, :admin) }

    let(:employee_a) do
      FactoryGirl.create(:regular_employee,
        status: 'inactive',
        leave_start_date: 1.month.ago,
        last_name: 'Aa')
    end
    let(:employee_b) do
      FactoryGirl.create(:regular_employee,
        status: 'inactive',
        leave_start_date: 1.week.ago,
        last_name: 'Bb')
    end
    let(:employee_c) do
      FactoryGirl.create(:regular_employee,
        status: 'inactive',
        leave_start_date: 1.day.ago,
        last_name: 'Cc')
    end
    let(:employee_d) do
      FactoryGirl.create(:regular_employee,
        status: 'active')
    end

    before do
      login_as user
    end

    it 'assigns all workers on leave as @inactives' do
      should_authorize(:index, :inactive)
      get :index
      expect(assigns(:inactives)).to eq([employee_a, employee_b, employee_c])
    end

    it 'sorts workers by leave start date' do
      get :index, { filterrific: { sorted_by: 'leave_start_date_desc'} }
      expect(assigns(:inactives)).to eq([employee_c, employee_b, employee_a])
    end
  end
end
