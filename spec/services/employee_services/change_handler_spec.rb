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
end
