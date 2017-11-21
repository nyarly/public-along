require 'rails_helper'

describe SummaryReportHelper, type: :helper do
  let!(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager,
                    hire_date: Date.today,
                    termination_date: Date.today + 1.week) }
  let(:sec_prof)  { FactoryGirl.create(:security_profile) }
  let(:helper)    { SummaryReportHelper::Csv.new }

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
    let(:emp_delta_group) { FactoryGirl.create_list(:emp_delta, 5,
      employee_id: employee.id,
      before: { some: "stuff"},
      after: { some: "new stuff"}) }

    it "should have the correct content and queue to send" do
      expect(EmpDelta).to receive(:report_group).and_return(emp_delta_group)

      helper.job_change_data
    end
  end
end
