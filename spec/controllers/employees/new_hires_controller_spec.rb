require 'rails_helper'

RSpec.describe Employees::NewHiresController, type: :controller do
  let(:user) { FactoryGirl.create(:user, :admin) }

  describe 'GET #index' do
    let(:location)            { FactoryGirl.create(:location) }
    let(:department)          { FactoryGirl.create(:department) }
    let(:manager)             { FactoryGirl.create(:manager) }
    let(:new_hire_a)          { FactoryGirl.create(:employee, last_name: 'Aaa', status: 'pending', manager: manager) }
    let(:new_hire_b)          { FactoryGirl.create(:employee, last_name: 'Bbb', status: 'pending', manager: manager) }
    let(:new_hire_c)          { FactoryGirl.create(:employee, last_name: 'Ccc', status: 'pending', manager: manager) }
    let(:rehire)              { FactoryGirl.create(:employee, last_name: 'Ddd', status: 'pending', manager: manager, hire_date: 1.year.ago) }
    let(:conversion)          { FactoryGirl.create(:employee, last_name: 'Eee', status: 'active', manager: manager, hire_date: 1.year.ago) }
    let(:onboarded_new_hire)  { FactoryGirl.create(:employee, last_name: 'Fff', status: 'pending', manager: manager) }
    let(:onboarded_emp_trans) { FactoryGirl.create(:emp_transaction, employee: onboarded_new_hire, kind: 'Onboarding') }

    before do
      login_as user

      FactoryGirl.create(:profile, employee: new_hire_a, start_date: 5.days.from_now, department: department)
      FactoryGirl.create(:profile, employee: new_hire_b, start_date: 4.days.from_now, location: location)
      FactoryGirl.create(:profile, employee: new_hire_c, start_date: 3.days.from_now)
      FactoryGirl.create(:profile, employee: rehire, start_date: 1.month.from_now, profile_status: 'pending')
      FactoryGirl.create(:profile, employee: rehire, start_date: 1.year.ago, profile_status: 'terminated', primary: false)
      FactoryGirl.create(:profile, employee: conversion, start_date: 2.weeks.from_now, profile_status: 'pending', primary: false)
      FactoryGirl.create(:profile, employee: conversion, start_date: 1.year.ago, profile_status: 'active')
      FactoryGirl.create(:profile, employee: onboarded_new_hire, start_date: 1.week.from_now)
      FactoryGirl.create(:onboarding_info, emp_transaction: onboarded_emp_trans)
    end

    it 'assigns all new hires as @new_hires' do
      should_authorize(:index, :new_hire)
      get :index
      expect(assigns(:new_hires)).to eq(
        [
          new_hire_c.current_profile,
          new_hire_b.current_profile,
          new_hire_a.current_profile,
          onboarded_new_hire.current_profile,
          conversion.profiles.pending.last,
          rehire.profiles.pending.last
        ]
      )
    end

    it 'filters by department' do
      get :index, { filterrific: { with_department_id: department.id } }
      expect(assigns(:new_hires)).to eq([new_hire_a.current_profile])
    end

    it 'filters by location' do
      get :index, { filterrific: { with_location_id: location.id } }
      expect(assigns(:new_hires)).to eq([new_hire_b.current_profile])
    end

    it 'sorts by start date asc' do
      get :index, { filterrific: { sorted_by: 'start_date_desc' } }
      expect(assigns(:new_hires)).to eq(
        [
          rehire.profiles.pending.last,
          conversion.profiles.pending.last,
          onboarded_new_hire.current_profile,
          new_hire_a.current_profile,
          new_hire_b.current_profile,
          new_hire_c.current_profile
        ]
      )
    end
  end
end
