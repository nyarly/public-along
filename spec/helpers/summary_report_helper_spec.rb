require 'rails_helper'

describe SummaryReportHelper, type: :helper do
  let!(:manager) { FactoryGirl.create(:regular_employee,
    first_name: 'Bob',
    last_name: 'Barker') }
  let!(:employee) { FactoryGirl.create(:employee,
    hire_date: Date.today,
    termination_date: Date.today + 1.week) }
  let!(:profile) { FactoryGirl.create(:profile,
    employee: employee,
    manager_id: manager.employee_id) }
  let(:emp_delta_group) { FactoryGirl.create_list(:emp_delta, 5,
    employee_id: manager.id,
    before: { some: "stuff"},
    after: { some: "new stuff"}) }
  let(:sec_prof) { FactoryGirl.create(:security_profile) }
  let(:helper) { SummaryReportHelper::Csv.new }

  context "onboarding" do
    it "should call the correct Employee scope" do
      expect(Employee).to receive(:onboarding_report_group).and_return([employee])

      helper.onboarding_data
    end

    it "should find buddy" do
      buddy = FactoryGirl.create(:regular_employee)
      emp_trans = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: employee.id)
      emp_sec_prof = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof.id)
      onboarding_info = FactoryGirl.create(:onboarding_info,
        buddy_id: buddy.id,
        emp_transaction: emp_trans)

      expect(helper.buddy(employee)).to eq(buddy)
    end

    it "should get the last changed date from the employee delta" do
      employee = FactoryGirl.create(:employee,
        created_at: 2.days.ago)
      emp_delta = FactoryGirl.create(:emp_delta,
        employee_id: employee.id,
        before: {thing: "thing"},
        after: {nothing: "nothing"},
        created_at: 1.day.ago)

      expect(helper.last_changed(employee)).to eq(emp_delta.created_at)
    end

    it "should get the last changed date from the onboarding info" do
      employee = FactoryGirl.create(:employee,
        created_at: 5.days.ago)
      emp_delta = FactoryGirl.create(:emp_delta,
        employee_id: employee.id,
        before: {thing: "thing"},
        after: {nothing: "nothing"},
        created_at: 4.days.ago)

      old_emp_trans = FactoryGirl.create(:onboarding_emp_transaction,
        created_at: 3.days.ago,
        employee_id: employee.id)
      old_onboarding = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: old_emp_trans.id,
        created_at: 3.days.ago)

      new_emp_trans = FactoryGirl.create(:onboarding_emp_transaction,
        created_at: 1.day.ago,
        employee_id: employee.id)
      new_onboarding = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: new_emp_trans.id,
        created_at: 1.day.ago)

      expect(helper.last_changed(employee)).to eq(new_onboarding.created_at)
    end

    it "should use the employee created date if there are no other changes" do
      employee = FactoryGirl.create(:employee,
        created_at: 5.days.ago)

      expect(helper.last_changed(employee)).to eq(employee.created_at)
    end
  end

  context "offboarding" do
    it "should have the correct content and queue to send" do
      expect(Employee).to receive(:offboarding_report_group).and_return([employee])
      helper.offboarding_data
    end

    it "should find employee assigned to take over salesforce cases" do
      salesforce = FactoryGirl.create(:regular_employee)
      emp_trans = FactoryGirl.create(:offboarding_emp_transaction,
        employee_id: employee.id,)
      emp_sec_prof = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof.id)
      offboarding_info = FactoryGirl.create(:offboarding_info,
        reassign_salesforce_id: salesforce.id,
        emp_transaction: emp_trans)
      expect(helper.salesforce(employee)).to eq(salesforce)
    end
  end

  context "job change" do
    it "should have the correct content and queue to send" do
      expect(EmpDelta).to receive(:report_group).and_return(emp_delta_group)

      helper.job_change_data
    end
  end
end
