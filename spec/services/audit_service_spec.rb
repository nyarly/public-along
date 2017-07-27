require 'rails_helper'

describe AuditService, type: :service do

  let(:regular_employee) { FactoryGirl.create(:employee,
    status: "Active")}
  let(:regular_termination) { FactoryGirl.create(:employee,
    status: "Terminated",
    termination_date: 1.week.ago)}
  let(:missed_offboard) { FactoryGirl.create(:employee,
    status: "Active",
    termination_date: 3.days.ago)}
  let(:missed_termination) { FactoryGirl.create(:employee,
    status: "Active",
    updated_at: 3.days.ago)}
  let(:contract_ended) { FactoryGirl.create(:employee,
    status: "Active",
    worker_type: WorkerType.find_by(kind: "Contractor"),
    contract_end_date: 1.week.ago)}

  context "when running an audit" do
    it "should find the missed termination" do
    end

    it "should find the missed offboard" do
    end

    it "should find the missed contract end" do
    end

    it "should return an array with the missed hashes" do
    end
  end

end
