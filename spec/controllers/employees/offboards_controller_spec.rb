require 'rails_helper'

RSpec.describe Employees::OffboardsController, type: :controller do
  describe 'GET #index' do
    let(:user) { FactoryGirl.create(:user, :admin) }
    let!(:employee_a) { FactoryGirl.create(:regular_employee, last_name: 'Aa', status: 'terminated', termination_date: 1.month.ago) }
    let!(:employee_b) { FactoryGirl.create(:regular_employee, last_name: 'Bb', status: 'terminated', termination_date: 1.week.ago) }
    let!(:employee_c) { FactoryGirl.create(:regular_employee, last_name: 'Cc', status: 'terminated', termination_date: Date.yesterday) }
    let!(:employee_d) { FactoryGirl.create(:regular_employee, last_name: 'Dd', status: 'terminated', contract_end_date: Date.yesterday) }
    let!(:employee_e) { FactoryGirl.create(:regular_employee, last_name: 'Ee', status: 'terminated', termination_date: Date.yesterday, offboarded_at: Date.yesterday) }

    before do
      login_as user
    end

    it 'assigns all workers terminated, offboarded, or contract ended in last two weeks as @offboards' do
      should_authorize(:index, :offboard)
      get :index
      expect(assigns(:offboards)).to eq([employee_b, employee_c, employee_d, employee_e])
    end

    it 'sorts by termination date' do
      get :index, { filterrific: { sorted_by: 'termination_date_desc' } }
      expect(assigns(:offboards)).to eq([employee_d, employee_c, employee_e, employee_b])
    end
  end
end
