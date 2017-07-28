require 'rails_helper'

describe AuditService, type: :service do

  let(:audit_service) { AuditService.new }
  let(:adp_service) { double(AdpService::Base) }
  let(:regular_worker_type) { FactoryGirl.create(:worker_type)}

  let!(:manager) { FactoryGirl.create(:employee) }
  let!(:regular_employee) { FactoryGirl.create(:employee,
    manager_id: manager.employee_id,
    status: "Active",
    worker_type_id: regular_worker_type.id)}
  let!(:regular_termination) { FactoryGirl.create(:employee,
    manager_id: manager.employee_id,
    status: "Terminated",
    termination_date: 1.week.ago,
    worker_type_id: regular_worker_type.id)}
  let!(:missed_offboard) { FactoryGirl.create(:employee,
    manager_id: manager.employee_id,
    status: "Active",
    termination_date: 3.days.ago,
    worker_type_id: regular_worker_type.id)}
  let!(:missed_termination) { FactoryGirl.create(:employee,
    manager_id: manager.employee_id,
    status: "Active",
    updated_at: 3.days.ago,
    worker_type_id: regular_worker_type.id)}
  let!(:missed_contract_end) { FactoryGirl.create(:employee,
    manager_id: manager.employee_id,
    status: "Active",
    worker_type_id: regular_worker_type.id,
    contract_end_date: 1.week.ago)}
  let!(:terminated_worker_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_termed_worker.json")}

  before :each do
    allow(AdpService::Base).to receive(:new).and_return(adp_service)
  end

  context "when running an audit" do

    it "should find the missed offboards" do
      allow(adp_service).to receive(:worker).and_return(JSON.parse(terminated_worker_json))
      missing_terminations = audit_service.check_for_missed_terminations
      expect(missing_terminations.length).to eq(3)
      expect(missing_terminations.any? { |hash| hash["name"] == "#{missed_termination.cn}"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash["name"] == "#{missed_offboard.cn}"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash["name"] == "#{missed_contract_end.cn}"}).to eq(true)
      expect(missing_terminations.any? { |hash| hash["name"] == "#{regular_termination.cn}"}).to eq(false)
      expect(missing_terminations.any? { |hash| hash["name"] == "#{regular_employee.cn}"}).to eq(false)
    end

    it "should check the adp status" do
      expect(adp_service).to receive(:worker).and_return(JSON.parse(terminated_worker_json)).thrice
      missing_terminations = audit_service.check_for_missed_terminations
      expect(missing_terminations.any? { |hash| hash["adp_status"] == "Terminated"}).to eq(true)
    end
  end

end
