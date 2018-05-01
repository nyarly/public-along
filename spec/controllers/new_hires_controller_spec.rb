require 'rails_helper'

RSpec.describe NewHiresController, type: :controller do
  describe 'GET #index' do
    let(:location_a)          { FactoryGirl.create(:location, name: 'Location A') }
    let(:location_b)          { FactoryGirl.create(:location, name: 'Location B') }
    let(:location_c)          { FactoryGirl.create(:location, name: 'Location C') }
    let(:department_a)        { FactoryGirl.create(:department, name: 'Department A') }
    let(:department_b)        { FactoryGirl.create(:department, name: 'Department B') }
    let(:department_c)        { FactoryGirl.create(:department, name: 'Department C') }
    let(:manager)             { FactoryGirl.create(:manager) }
    let(:new_hire_a)          { FactoryGirl.create(:employee, last_name: 'Aaa', status: 'pending', manager: manager) }
    let(:new_hire_b)          { FactoryGirl.create(:employee, last_name: 'Bbb', status: 'pending', manager: manager) }
    # let(:new_hire_c)          { FactoryGirl.create(:employee, last_name: 'Ccc', status: 'pending', manager: manager) }
    # let(:rehire)              { FactoryGirl.create(:employee, last_name: 'Ddd', status: 'pending', manager: manager, hire_date: 1.year.ago) }
    # let(:conversion)          { FactoryGirl.create(:employee, last_name: 'Eee', status: 'active', manager: manager, hire_date: 1.year.ago) }
    # let(:onboarded_new_hire)  { FactoryGirl.create(:employee, last_name: 'Fff', status: 'pending', manager: manager) }
    # let(:onboarded_emp_trans) { FactoryGirl.create(:emp_transaction, employee: onboarded_new_hire, kind: 'Onboarding') }

    before do
      # login_as user

      FactoryGirl.create(:profile, employee: new_hire_a, start_date: 5.days.from_now)
      FactoryGirl.create(:profile, employee: new_hire_b, start_date: 4.days.from_now)
      # FactoryGirl.create(:profile, employee: new_hire_c, start_date: 3.days.from_now)
      # FactoryGirl.create(:profile, employee: rehire, start_date: 1.month.from_now, profile_status: 'pending')
      # FactoryGirl.create(:profile, employee: rehire, start_date: 1.year.ago, profile_status: 'terminated', primary: false)
      # FactoryGirl.create(:profile, employee: conversion, start_date: 2.weeks.from_now, profile_status: 'pending', primary: false)
      # FactoryGirl.create(:profile, employee: conversion, start_date: 1.year.ago, profile_status: 'active')
      # FactoryGirl.create(:profile, employee: onboarded_new_hire, start_date: 1.week.from_now)
      # FactoryGirl.create(:onboarding_info, emp_transaction: onboarded_emp_trans)
    end

    it 'assigns all new hires as @new_hires' do
      get :index
      expect(assigns(:new_hires)).to eq([new_hire_a.current_profile, new_hire_b.current_profile, new_hire_c.current_profile])
    end

    context 'when sorted by employee last name DESC' do
    end

    context 'when sorted by start date ASC' do
      it 'orders new hires by earliest start date' do
        get :index, { model: 'profiles', column: 'start_date', direction: 'asc' }
        expect(assigns(:new_hires)).to eq([new_hire_a.current_profile, new_hire_b.current_profile])
      end

    context 'when sorted by start date DESC' do
      it 'orders new hires by latest start date' do
        get :index, { model: 'profiles', column: 'start_date', direction: 'desc' }
        expect(assigns(:new_hires)).to eq([new_hire_b.current_profile, new_hire_a.current_profile])
      end
    end

    context 'when sorted by department ASC' do
    end

    context 'when sorted by department DESC' do
    end

    context 'when sorted by location ASC' do
    end

    context 'when sorted by location DESC' do
    end
  end
end
