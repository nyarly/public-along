require 'rails_helper'

describe SummaryReportHelper, type: :helper do
  let(:manager)   { FactoryGirl.create(:employee, first_name: 'Bob', last_name: 'Barker') }
  let(:emp_group) { FactoryGirl.create_list(:employee, 5,
                                            hire_date: Date.today,
                                            termination_date: Date.today + 1.week,
                                            manager_id: manager.employee_id) }
  let(:emp_delta_group) { FactoryGirl.create_list(:emp_delta, 5,
                                                  employee_id: manager.id,
                                                  before: { some: "stuff"},
                                                  after: { some: "new stuff"}) }
  let(:sec_prof)  { FactoryGirl.create(:security_profile) }
  let(:helper)     { SummaryReportHelper::Csv.new }

  context "onboarding" do
    it "should call the correct Employee scope" do
      expect(Employee).to receive(:onboarding_report_group).and_return(emp_group)

      helper.onboarding_data
    end

    it "should find buddy" do
      buddy = FactoryGirl.create(:employee)
      emp_trans = FactoryGirl.create(:emp_transaction, :kind => "Onboarding")
      emp_sec_prof = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans.id, employee_id: emp_group[0].id, security_profile_id: sec_prof.id)
      onboarding_info = FactoryGirl.create(:onboarding_info, employee_id: emp_group[0].id, buddy_id: buddy.id, emp_transaction: emp_trans)

      expect(helper.buddy(emp_group[0])).to eq(buddy)
    end
  end

  context "offboarding" do
    it "should have the correct content and queue to send" do
      expect(Employee).to receive(:offboarding_report_group).and_return(emp_group)

      helper.offboarding_data
    end

    it "should find employee assigned to take over salesforce cases" do
      salesforce = FactoryGirl.create(:employee)
      emp_trans = FactoryGirl.create(:emp_transaction, :kind => "Offboarding")
      emp_sec_prof = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans.id, employee_id: emp_group[0].id, security_profile_id: sec_prof.id)
      offboarding_info = FactoryGirl.create(:offboarding_info, employee_id: emp_group[0].id, reassign_salesforce_id: salesforce.id, emp_transaction: emp_trans)

      expect(helper.salesforce(emp_group[0])).to eq(salesforce)
    end
  end

  context "job change" do
    it "should have the correct content and queue to send" do
      expect(EmpDelta).to receive(:report_group).and_return(emp_delta_group)

      helper.job_change_data
    end
  end
end
