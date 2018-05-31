require 'rails_helper'

RSpec.describe JobChangeForm do
  let!(:type)       { FactoryGirl.create(:worker_type, code: 'ACW', name: 'Contractor') }
  let!(:employee)   { FactoryGirl.create(:employee) }
  let(:user)        { FactoryGirl.create(:user, employee: employee) }
  let(:conversion)  { FactoryGirl.create(:contract_worker) }
  let(:json)        { File.read(Rails.root.to_s + '/spec/fixtures/adp_cat_change_hire_event.json') }
  let(:event)       { FactoryGirl.create(:adp_event, json: json, status: 'new', kind: 'worker.hire') }
  let(:emp_trans)   { FactoryGirl.build(:emp_transaction, kind: 'job_change', user: user, employee: conversion) }

  describe '#save' do
    context 'worker type change' do
      subject(:job_change_form) { JobChangeForm.new(params) }

      let(:params) do
        {
          employee_id: conversion.id,
          event_id: event.id,
          link_accounts: true,
          linked_account_id: conversion.id,
          buddy_id: employee.id,
          cw_email: 'true',
          cw_google_membership: 'true'
        }
      end

      before do
        job_change_form.emp_transaction = emp_trans
      end

      it 'creates an emp transaction' do
        expect {
          job_change_form.save
        }.to change { EmpTransaction.count }.by(1)
      end

      it 'creates an emp transaction with the right info' do
        job_change_form.save
        expect(job_change_form.emp_transaction.user).to eq(user)
        expect(job_change_form.emp_transaction.kind).to eq('job_change')
        expect(job_change_form.emp_transaction.employee).to eq(conversion)
      end

      it 'creates one onboarding info' do
        expect {
          job_change_form.save
        }.to change { OnboardingInfo.count }.by(1)
      end

      it 'creates an onboarding info with the right information' do
        job_change_form.save
        expect(job_change_form.emp_transaction.onboarding_infos.last.buddy_id)
          .to eq(employee.id)
        expect(job_change_form.emp_transaction.onboarding_infos.last.cw_email)
          .to eq(true)
        expect(job_change_form.emp_transaction.onboarding_infos.last.cw_google_membership)
          .to eq(true)
      end

      it 'adds a pending profile to the converting worker' do
        job_change_form.save
        expect(conversion.reload)
      end
    end
  end
end
