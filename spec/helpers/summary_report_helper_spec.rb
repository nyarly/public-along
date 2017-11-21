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
    let!(:old_job)        { FactoryGirl.create(:job_title) }
    let!(:new_job)        { FactoryGirl.create(:job_title) }
    let(:manager)         { FactoryGirl.create(:active_employee) }
    let(:emp_1)           { FactoryGirl.create(:active_employee,
                            manager: manager) }
    let(:emp_2)           { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_1)    { FactoryGirl.create(:emp_delta,
                            employee: emp_1,
                            before: {"job_title_id"=>"#{old_job.id}", "first_name"=>"name1"},
                            after: {"job_title_id"=>"#{new_job.id}", "first_name"=>"name2"}) }
    let!(:emp_delta_2)    { FactoryGirl.create(:emp_delta,
                            employee: emp_2,
                            before: {"job_title_id"=>"#{old_job.id}"},
                            after: {"job_title_id"=>"#{new_job.id}"}) }

    let(:csv) {
      <<-EOS.strip_heredoc
      Employee ID,First Name,Last Name,Job Title,Manager Full Name,Department,Location,Start Date,Change Type,Old Value,New Value,Changed At,Worker Type
      #{emp_1.current_profile.adp_employee_id},#{emp_1.first_name},#{emp_1.last_name},#{emp_1.job_title.name},#{manager.cn},#{emp_1.department.name},#{emp_1.location.name},#{emp_1.current_profile.start_date},First Name,name1,name2,#{emp_delta_1.created_at},#{emp_1.worker_type.name}
      #{emp_1.current_profile.adp_employee_id},#{emp_1.first_name},#{emp_1.last_name},#{emp_1.job_title.name},#{manager.cn},#{emp_1.department.name},#{emp_1.location.name},#{emp_1.current_profile.start_date},Job Title,#{old_job.name},#{new_job.name},#{emp_delta_1.created_at},#{emp_1.worker_type.name}
      #{emp_2.current_profile.adp_employee_id},#{emp_2.first_name},#{emp_2.last_name},#{emp_2.job_title.name},,#{emp_2.department.name},#{emp_2.location.name},#{emp_2.current_profile.start_date},Job Title,#{old_job.name},#{new_job.name},#{emp_delta_2.created_at},#{emp_2.worker_type.name}
      EOS
    }

    it "should have the correct content and queue to send" do
      expect(EmpDelta).to receive(:report_group).and_return(emp_delta_group)
      helper.job_change_data
    end

    it "should outupt the correct csv" do
      data = helper.job_change_data
      expect(data).to eq(csv)
    end
  end
end
