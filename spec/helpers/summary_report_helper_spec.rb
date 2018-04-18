require 'rails_helper'

describe SummaryReportHelper, type: :helper do
  let(:helper)    { SummaryReportHelper::Csv.new }
  let(:manager) { FactoryGirl.create(:active_employee) }

  describe '#offboarding_data' do
    context 'with offboard form' do
      subject(:data) { helper.offboarding_data }

      let(:transferred_to) { FactoryGirl.create(:regular_employee) }
      let!(:employee) do
        FactoryGirl.create(:active_employee,
          manager: manager,
          termination_date: Date.today)
      end
      let(:transaction) do
        FactoryGirl.create(:offboarding_emp_transaction,
        employee_id: employee.id)
      end
      let!(:info) do
        FactoryGirl.create(:offboarding_info,
          emp_transaction: transaction,
          reassign_salesforce_id: transferred_to.id)
      end

      let(:csv) do
        <<-EOS.strip_heredoc
        Name,Employee ID,Worker Type,Position,Department,Manager,Work Location,Email,Transfer Salesforce Cases,Start Date,Termination Date,Contract End Date,Offboarding Form Submitted,Offboarded At,Worker Info Last Modified
        #{employee.cn},#{employee.employee_id},#{employee.worker_type.name},#{employee.job_title.name},#{employee.department.name},#{employee.manager.cn},#{employee.location.name},#{employee.email},#{transferred_to.cn},#{employee.hire_date.strftime('%Y-%b-%e')},#{Date.today.strftime('%Y-%b-%e')},,#{transaction.created_at.strftime('%Y-%m-%d %H:%M:%S')},,#{employee.created_at.strftime('%Y-%m-%d %H:%M:%S')}
        EOS
      end

      it 'has the correct content' do
        expect(data).to eq(csv)
      end
    end

    context 'without offboard form' do
      subject(:data) { helper.offboarding_data }

      let!(:employee) do
        FactoryGirl.create(:terminated_employee,
          termination_date: Date.yesterday,
          offboarded_at: Date.yesterday,
          manager: manager)
      end

      let(:csv) do
        <<-EOS.strip_heredoc
        Name,Employee ID,Worker Type,Position,Department,Manager,Work Location,Email,Transfer Salesforce Cases,Start Date,Termination Date,Contract End Date,Offboarding Form Submitted,Offboarded At,Worker Info Last Modified
        #{employee.cn},#{employee.employee_id},#{employee.worker_type.name},#{employee.job_title.name},#{employee.department.name},#{employee.manager.cn},#{employee.location.name},#{employee.email},,#{employee.hire_date.strftime('%Y-%b-%e')},#{Date.yesterday.strftime('%Y-%b-%e')},,none,#{Date.yesterday.strftime('%Y-%b-%e')},#{employee.current_profile.created_at.strftime('%Y-%m-%d %H:%M:%S')}
        EOS
      end

      it 'has the correct content' do
        expect(data).to eq(csv)
      end
    end

    context 'when terminated contractor' do
      subject(:data) { helper.offboarding_data }

      let!(:worker) do
        FactoryGirl.create(:contract_worker,
          offboarded_at: Date.yesterday,
          contract_end_date: Date.yesterday,
          manager: manager)
      end

      let(:csv) do
        <<-EOS.strip_heredoc
        Name,Employee ID,Worker Type,Position,Department,Manager,Work Location,Email,Transfer Salesforce Cases,Start Date,Termination Date,Contract End Date,Offboarding Form Submitted,Offboarded At,Worker Info Last Modified
        #{worker.cn},#{worker.employee_id},#{worker.worker_type.name},#{worker.job_title.name},#{worker.department.name},#{worker.manager.cn},#{worker.location.name},#{worker.email},,#{worker.hire_date.strftime('%Y-%b-%e')},,#{Date.yesterday.strftime('%Y-%b-%e')},none,#{Date.yesterday.strftime('%Y-%b-%e')},#{worker.created_at.strftime('%Y-%m-%d %H:%M:%S')}
        EOS
      end

      it 'has the correct content' do
        expect(data).to eq(csv)
      end
    end
  end

  describe '#job_change_data' do
    let(:parent_org_1)    { FactoryGirl.create(:parent_org, name: "A_org") }
    let(:parent_org_2)    { FactoryGirl.create(:parent_org, name: "B_org") }
    let(:dept_1)          { FactoryGirl.create(:department,
                            name: "A_dept",
                            parent_org: parent_org_1) }
    let(:dept_2)          { FactoryGirl.create(:department,
                            name: "B_dept",
                            parent_org: parent_org_2) }
    let(:dept_3)          { FactoryGirl.create(:department,
                            name: "C_dept",
                            parent_org: parent_org_2) }
    let!(:old_job)        { FactoryGirl.create(:job_title) }
    let!(:new_job)        { FactoryGirl.create(:job_title) }
    let(:old_manager)     { FactoryGirl.create(:active_employee) }
    let(:manager)         { FactoryGirl.create(:active_employee) }
    let(:emp_1)           { FactoryGirl.create(:employee,
                            manager: manager) }
    let!(:emp_1_profile)  { FactoryGirl.create(:profile,
                            employee: emp_1,
                            department: dept_3) }
    let(:emp_2)           { FactoryGirl.create(:employee) }
    let!(:emp_2_profile)  { FactoryGirl.create(:profile,
                            employee: emp_2,
                            department: dept_2) }
    let(:emp_3)           { FactoryGirl.create(:employee) }
    let!(:emp_3_profile)  { FactoryGirl.create(:profile,
                            employee: emp_3,
                            department: dept_1) }
    let!(:emp_delta_1)    { FactoryGirl.create(:emp_delta,
                            employee: emp_1,
                            before: {"job_title_id"=>"#{old_job.id}", "first_name"=>"name1"},
                            after: {"job_title_id"=>"#{new_job.id}", "first_name"=>"name2"}) }
    let!(:emp_delta_2)    { FactoryGirl.create(:emp_delta,
                            employee: emp_2,
                            before: {"job_title_id"=>"#{old_job.id}"},
                            after: {"job_title_id"=>"#{new_job.id}"}) }
    let!(:emp_delta_3)    { FactoryGirl.create(:emp_delta,
                            employee: emp_3,
                            before: {"job_title_id"=>"#{old_job.id}", "manager_id"=>"#{old_manager.id}", "manager_adp_employee_id"=>"#{old_manager.current_profile.adp_employee_id}"},
                            after: {"job_title_id"=>"#{new_job.id}", "manager_id"=>"#{manager.id}", "manager_adp_employee_id"=>"#{manager.current_profile.adp_employee_id}"}) }


    let(:csv) {
      <<-EOS.strip_heredoc
      Parent Department,Department,First Name,Last Name,Employee ID,ADP Job Title,Manager Full Name,Location,Start Date,Change Type,Old Value,New Value,Change Time Stamp
      A_org,A_dept,#{emp_3.first_name},#{emp_3.last_name},#{emp_3.current_profile.adp_employee_id},#{emp_3.job_title.name},,#{emp_3.location.name},#{emp_3.current_profile.start_date.strftime("%Y-%m-%d")},Manager,#{old_manager.cn},#{manager.cn},#{emp_delta_3.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S")}
      A_org,A_dept,#{emp_3.first_name},#{emp_3.last_name},#{emp_3.current_profile.adp_employee_id},#{emp_3.job_title.name},,#{emp_3.location.name},#{emp_3.current_profile.start_date.strftime("%Y-%m-%d")},Job Title,#{old_job.name},#{new_job.name},#{emp_delta_3.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S")}
      A_org,A_dept,#{emp_3.first_name},#{emp_3.last_name},#{emp_3.current_profile.adp_employee_id},#{emp_3.job_title.name},,#{emp_3.location.name},#{emp_3.current_profile.start_date.strftime("%Y-%m-%d")},Manager Employee ID,#{old_manager.current_profile.adp_employee_id},#{manager.current_profile.adp_employee_id},#{emp_delta_3.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S")}
      B_org,B_dept,#{emp_2.first_name},#{emp_2.last_name},#{emp_2.current_profile.adp_employee_id},#{emp_2.job_title.name},,#{emp_2.location.name},#{emp_2.current_profile.start_date.strftime("%Y-%m-%d")},Job Title,#{old_job.name},#{new_job.name},#{emp_delta_2.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S")}
      B_org,C_dept,#{emp_1.first_name},#{emp_1.last_name},#{emp_1.current_profile.adp_employee_id},#{emp_1.job_title.name},#{manager.cn},#{emp_1.location.name},#{emp_1.current_profile.start_date.strftime("%Y-%m-%d")},First Name,name1,name2,#{emp_delta_1.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S")}
      B_org,C_dept,#{emp_1.first_name},#{emp_1.last_name},#{emp_1.current_profile.adp_employee_id},#{emp_1.job_title.name},#{manager.cn},#{emp_1.location.name},#{emp_1.current_profile.start_date.strftime("%Y-%m-%d")},Job Title,#{old_job.name},#{new_job.name},#{emp_delta_1.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S")}
      EOS
    }

    it "should outupt the correct csv" do
      data = helper.job_change_data
      expect(data).to eq(csv)
    end
  end
end
