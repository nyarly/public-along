require 'rails_helper'

RSpec.describe EmployeeProfile do
  let!(:worker_type) { FactoryGirl.create(:worker_type,
    code: "FTR",
    name: "Regular Full-Time")}
  let(:department) { FactoryGirl.create(:department,
    code: "125000",
    name: "Inside Sales")}
  let(:location) { Location.find_by(
    code: "LOS",
    name: "Los Angeles Office")}
  let(:job_title) { FactoryGirl.create(:job_title,
    code: "SADEN",
    name: "Sales Associate")}
  let!(:employee) { FactoryGirl.create(:employee,
    first_name: "Jane",
    last_name: "Goodall",
    status: "Active",
    hire_date: Date.new(2014, 6, 1),
    contract_end_date: nil,
    office_phone: nil,
    personal_mobile_phone: "(888) 888-8888") }
  let!(:profile) { FactoryGirl.create(:profile,
    employee: employee,
    adp_assoc_oid: "AAABBBCCCDDD",
    adp_employee_id: "123456",
    company: "OpenTable, Inc.",
    department: department,
    job_title: job_title,
    location: location,
    manager_id: "654321",
    profile_status: "Active",
    start_date: Date.new(2017, 01, 01),
    worker_type: worker_type )}
  let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_worker.json"))}
  let(:parser) { AdpService::WorkerJsonParser.new }

  context "existing employee with updated employee info" do

      it "should update the info" do
        employee.last_name = "Good All"
        w_hash = parser.gen_worker_hash(json["workers"][0])
        profiler = EmployeeProfile.new
        stuff = profiler.do_stuff(w_hash)
        expect(employee.reload.last_name).to eq("Goodall")
      end

      it "should not create a new profile" do
        employee.last_name = "Good All"
        w_hash = parser.gen_worker_hash(json["workers"][0])
        profiler = EmployeeProfile.new
        stuff = profiler.do_stuff(w_hash)
        expect(Employee.count).to eq(1)
        expect(employee.profiles.count).to eq(1)
      end

  end

  context "existing employee with no change to profile" do
    it "should do the thing" do
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      stuff = profiler.do_stuff(w_hash)
      expect(Employee.count).to eq(1)
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.profiles.count).to eq(1)
      expect(employee.profiles.active).to eq(profile)
    end
  end

  context "existing employee with updated profile" do
    let!(:old_worker_type) { FactoryGirl.create(:worker_type,
      code: "OLD",
      name: "Contractor")}
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      adp_assoc_oid: "AAABBBCCCDDD",
      adp_employee_id: "123456",
      company: "OpenTable, Inc.",
      department: department,
      job_title: job_title,
      location: location,
      manager_id: "654321",
      profile_status: "Active",
      start_date: Date.new(2016, 6, 1),
      worker_type: old_worker_type )}

    it "should create a new profile when given a new worker type" do
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      stuff = profiler.do_stuff(w_hash)
      expect(Employee.count).to eq(1)
      expect(employee.profiles.count).to eq(2)
      expect(employee.profiles.active.worker_type).to eq(worker_type)
      expect(employee.profiles.active.profile_status).to eq("Active")
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.profiles.expired.count).to eq(1)
      expect(employee.profiles.expired[0].profile_status).to eq("Expired")
      expect(employee.profiles.expired[0].worker_type).to eq(old_worker_type)
      expect(employee.profiles.expired[0].end_date).to eq(Date.today)
    end
  end

  context "new employee" do
  end
end
