require 'rails_helper'

describe SummaryReportHelper, type: :helper do
  let!(:employee) { FactoryGirl.create(:employee, :with_profile, :with_manager,
                    hire_date: Date.today,
                    termination_date: Date.today + 1.week) }
  let(:sec_prof)  { FactoryGirl.create(:security_profile) }
  let(:helper)    { SummaryReportHelper::Csv.new }

  context "onboarding" do
    let!(:rehire) { FactoryGirl.create(:employee,
      hire_date: 3.years.ago,
      request_status: "waiting") }
    let!(:re_new_p) { FactoryGirl.create(:profile,
      employee: rehire,
      start_date: 1.week.from_now) }
    let!(:re_old_p) { FactoryGirl.create(:terminated_profile,
      employee: rehire,
      start_date: 3.years.ago)}

    it "should call the correct Employee scope" do
      expect(Profile).to receive(:onboarding_report_group).and_return([employee.current_profile, re_new_p])
      helper.onboarding_data
    end

    it "should find buddy" do
      buddy = FactoryGirl.create(:employee)
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
