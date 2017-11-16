require 'rails_helper'

describe EmployeeService::ChangeHandler, type: :service do

  context "contract end date" do
    let(:employee)            { FactoryGirl.create(:contract_worker) }
    let(:extended_contractor) { FactoryGirl.create(:contract_worker,
                                status: "active",
                                request_status: "waiting",
                                contract_end_date: Date.new(2017, 11, 17)) }
    let!(:emp_delta)          { FactoryGirl.create(:emp_delta,
                                employee: extended_contractor,
                                before: {"contract_end_date"=>"2017-11-17 00:00:00 UTC"},
                                after: {"contract_end_date"=>"2018-01-01 00:00:00 UTC"}) }

    let(:pending_contractor)  { FactoryGirl.create(:contract_worker,
                                status: "pending",
                                request_status: "waiting",
                                hire_date: Date.new(2017, 11, 14),
                                contract_end_date: Date.new(2017, 12, 31)) }
    let!(:emp_delta_2)        { FactoryGirl.create(:emp_delta,
                                employee: pending_contractor,
                                before: {"contract_end_date"=>"2017-12-31 00:00:00 UTC"},
                                after: {"contract_end_date"=>"2018-01-01 00:00:00 UTC"}) }

    before :each do
      Timecop.freeze(Time.new(2017, 11, 13, 9, 0, 0, "-08:00"))
    end

    after :each do
      Timecop.return
    end

    it "should do nothing if there are no changes" do
      EmployeeService::ChangeHandler.new(employee).call
      expect(employee.request_status).to eq("none")
    end

    it "should clear request status when contract extended" do
      EmployeeService::ChangeHandler.new(extended_contractor).call
      expect(extended_contractor.request_status).to eq("none")
    end

    it "should not clear request for pending contractors" do
      EmployeeService::ChangeHandler.new(pending_contractor).call
      expect(pending_contractor.request_status).to eq("waiting")
    end
  end

  context "manager" do
    let(:emp_1)       { FactoryGirl.create(:regular_employee) }
    let(:old_manager) { FactoryGirl.create(:regular_employee) }
    let(:manager)     { FactoryGirl.create(:regular_employee) }
    let(:emp_2)       { FactoryGirl.create(:regular_employee,
                        manager: manager) }
    let!(:emp_delta)  { FactoryGirl.create(:emp_delta,
                        employee: emp_2,
                        before: {"manager_id"=>"#{old_manager.id}"},
                        after: {"manager_id"=>"#{manager.id}"}) }

    it "should do nothing if the manager does not change" do
      expect(EmployeeService::GrantManagerAccess).not_to receive(:new)
      EmployeeService::ChangeHandler.new(emp_1).call
    end

    it "should call the manager access service when manager changes" do
      expect(EmployeeService::GrantManagerAccess).to receive_message_chain(:new, :process!)
      EmployeeService::ChangeHandler.new(emp_2).call
    end
  end

  context "department/job_title/location changes" do
    let(:old_location) { FactoryGirl.create(:location) }
    let(:new_location) { FactoryGirl.create(:location) }
    let(:old_dept)     { FactoryGirl.create(:department) }
    let(:new_dept)     { FactoryGirl.create(:department) }
    let(:old_job)      { FactoryGirl.create(:job_title) }
    let(:new_job)      { FactoryGirl.create(:job_title) }
    let(:emp_1)        { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_1) { FactoryGirl.create(:emp_delta,
                         employee: emp_1,
                         before: {"first_name"=>"name"},
                         after: {"first_name"=>"name1"}) }
    let(:emp_2)        { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_2) { FactoryGirl.create(:emp_delta,
                         employee: emp_2,
                         before: {"location_id"=>"#{old_location.id}"},
                         after: {"location_id"=>"#{new_location.id}"}) }
    let(:emp_3)        { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_3) { FactoryGirl.create(:emp_delta,
                         employee: emp_3,
                         before: {"department_id"=>"#{old_dept.id}"},
                         after: {"department_id"=>"#{new_dept.id}"}) }
    let(:emp_4)        { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_4) { FactoryGirl.create(:emp_delta,
                         employee: emp_4,
                         before: {"job_title_id"=>"#{old_job.id}"},
                         after: {"job_title_id"=>"#{new_job.id}"}) }
    let(:emp_5)        { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_5) { FactoryGirl.create(:emp_delta,
                         employee: emp_5,
                         before: {"job_title_id"=>"#{old_job.id}"},
                         after: {"job_title_id"=>"#{new_job.id}"}) }
    let!(:emp_delta_6) { FactoryGirl.create(:emp_delta,
                         employee: emp_5,
                         before: {"job_title_id"=>"#{old_job.id}"},
                         after: {"job_title_id"=>"#{new_job.id}"}) }
    let(:emp_6)        { FactoryGirl.create(:regular_employee,
                         status: "pending") }
    let!(:emp_delta_7) { FactoryGirl.create(:emp_delta,
                         employee: emp_6,
                         before: {"job_title_id"=>"#{old_job.id}"},
                         after: {"job_title_id"=>"#{new_job.id}"}) }


    it "should not send security access form if department/job title/location does not change" do
      expect(EmployeeWorker).not_to receive(:perform_async)
      EmployeeService::ChangeHandler.new(emp_1).call
    end

    it "should not send security access form if had recent change" do
      expect(EmployeeWorker).not_to receive(:perform_async)
      EmployeeService::ChangeHandler.new(emp_5).call
    end

    it "should not send security access form if worker is not active" do
      expect(EmployeeWorker).not_to receive(:perform_async)
      EmployeeService::ChangeHandler.new(emp_6).call
    end

    it "should send security access form if location changes" do
      expect(EmployeeWorker).to receive(:perform_async)
      EmployeeService::ChangeHandler.new(emp_2).call
    end

    it "should send security access form if department changes" do
      expect(EmployeeWorker).to receive(:perform_async)
      EmployeeService::ChangeHandler.new(emp_3).call
    end

    it "should send security access form if job title changes" do
      expect(EmployeeWorker).to receive(:perform_async)
      EmployeeService::ChangeHandler.new(emp_4).call
    end
  end
end
