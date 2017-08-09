require 'rails_helper'
require 'rake'

describe "profile rake tasks", type: :tasks do
  let(:adp_service) { double(AdpService::Base) }
  let(:worker_json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_worker.json")) }
  let(:department) { Department.find_or_create_by!(code: "125000", name: "Inside Sales", status: "Active") }
  let(:worker_type) { WorkerType.find_or_create_by!(code: "FTR", name: "Regular Full-Time", status: "Active") }
  let(:location) { Location.find_or_create_by!(code: "LOS", name: "Los Angeles Office", status: "Active") }
  let(:job_title) { JobTitle.find_or_create_by!(code: "SADEN", name: "Sales Associate", status: "Active") }

  let!(:employee) { FactoryGirl.create(:employee,
    status: "Active",
    employee_id: "123456",
    hire_date: Date.new(2014, 6, 1),
    manager_id: "654321",
    adp_assoc_oid: "AAABBBCCCDDD",
    department: department,
    job_title: job_title,
    worker_type: worker_type,
    location: location,
    company: "OpenTable, Inc."
  )}

  context "initial population" do

    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/profiles", [Rails.root.to_s], ''
      Rake::Task.define_task :environment
    end

    it "creates an employee profile and populates it with the correct info" do
      allow(AdpService::Base).to receive(:new).and_return(adp_service)
      allow(adp_service).to receive(:worker).and_return(worker_json)
      Rake::Task["profiles:initial_population"].invoke

      expect(employee.profiles.count).to eq(1)
      expect(employee.profiles[0].status).to eq("Active")
      expect(employee.profiles[0].start_date).to eq(Date.new(2017, 01, 01))
      expect(employee.profiles[0].end_date).to eq(nil)
      expect(employee.profiles[0].manager_id).to eq("654321")
      expect(employee.profiles[0].department_id).to eq(department.id)
      expect(employee.profiles[0].worker_type_id).to eq(worker_type.id)
      expect(employee.profiles[0].location_id).to eq(location.id)
      expect(employee.profiles[0].job_title_id).to eq(job_title.id)
      expect(employee.profiles[0].company).to eq("OpenTable, Inc.")
      expect(employee.profiles[0].adp_assoc_oid).to eq("AAABBBCCCDDD")
      expect(employee.profiles[0].adp_employee_id).to eq("123456")
      expect(employee.hire_date).to eq(Date.new(2014, 6, 1))
    end
  end
end
