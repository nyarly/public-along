require 'rails_helper'

RSpec.describe EmployeeProfile do
  let!(:worker_type) { FactoryGirl.create(:worker_type,
    code: "FTR",
    name: "Regular Full-Time")}
  let!(:department) { FactoryGirl.create(:department,
    code: "125000",
    name: "Inside Sales")}
  let(:location) { Location.find_by(
    code: "LOS",
    name: "Los Angeles Office")}
  let(:job_title) { FactoryGirl.create(:job_title,
    code: "SADEN",
    name: "Sales Associate")}
  let(:employee) { FactoryGirl.create(:active_employee,
    first_name: "Jane",
    last_name: "Goodall",
    hire_date: Date.new(2014, 6, 1),
    contract_end_date: nil,
    office_phone: nil,
    # status: "active",
    personal_mobile_phone: "(888) 888-8888",
    business_card_title: job_title.name) }
  let!(:profile) { FactoryGirl.create(:profile,
    employee: employee,
    adp_assoc_oid: "AAABBBCCCDDD",
    adp_employee_id: "123456",
    company: "OpenTable, Inc.",
    department: department,
    job_title: job_title,
    location: location,
    manager_id: "654321",
    start_date: Date.new(2017, 01, 01),
    worker_type: worker_type )}
  let(:json) { JSON.parse(File.read(Rails.root.to_s+"/spec/fixtures/adp_worker.json"))}
  let(:parser) { AdpService::WorkerJsonParser.new }

  context "sync existing employee with updated employee info" do
    it "should update the info" do
      employee.last_name = "Good All"
      employee.save
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      profiler.update_employee(employee, w_hash)

      expect(employee.reload.last_name).to eq("Goodall")
      expect(employee.emp_deltas.last.before).to eq({"last_name"=>"Good All"})
      expect(employee.emp_deltas.last.after).to eq({"last_name"=>"Goodall"})
    end

    it "should not create a new profile" do
      employee.last_name = "Good All"
      employee.save
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      profiler.update_employee(employee, w_hash)

      expect(Employee.count).to eq(1)
      expect(employee.profiles.count).to eq(1)
    end
  end

  context "sync existing employee with no change to profile" do
    it "should not make any changes" do
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      profiler.update_employee(employee, w_hash)

      expect(Employee.count).to eq(1)
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.profiles.count).to eq(1)
      expect(employee.profiles.active).to eq(profile)
    end
  end

  context "sync existing employee with updated profile" do
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
      profile_status: "active",
      start_date: Date.new(2016, 6, 1),
      worker_type: old_worker_type )}

    it "should create a new profile when going from contract to full-time" do
      expect(EmployeeWorker).not_to receive(:perform_async)
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      profiler.update_employee(employee, w_hash)
      employee = Employee.find_by_employee_id("123456")
      employee.reload

      expect(Employee.count).to eq(1)
      expect(employee.profiles.count).to eq(2)
      expect(employee.status).to eq("active")
      expect(employee.current_profile.profile_status).to eq("active")
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.profiles.terminated).to eq(profile)
      expect(employee.profiles.terminated.profile_status).to eq("terminated")
      expect(employee.profiles.terminated.worker_type).to eq(old_worker_type)
      expect(employee.emp_deltas.last.before).to eq({"start_date"=>"2016-06-01 00:00:00 UTC", "worker_type_id"=>"#{old_worker_type.id}"})
      expect(employee.emp_deltas.last.after).to eq({"start_date"=>"2017-01-01 00:00:00 UTC", "worker_type_id"=>"#{worker_type.id}"})
    end
  end

  context "sync existing employee with employee info and worker type profile change" do
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
      profile_status: "active",
      start_date: Date.new(2016, 6, 1),
      worker_type: old_worker_type )}

    it "should update employee info" do
      expect(EmployeeWorker).not_to receive(:perform_async)

      employee.last_name = "Good All"
      employee.save
      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      profiler.update_employee(employee, w_hash)

      expect(Employee.count).to eq(1)
      expect(employee.profiles.count).to eq(2)
      expect(employee.reload.last_name).to eq("Goodall")
      expect(employee.hire_date).to eq(Date.new(2014, 6, 1))
      expect(employee.emp_deltas.count).to eq(1)
      expect(employee.emp_deltas.last.before).to eq({"last_name"=>"Good All", "start_date"=>"2016-06-01 00:00:00 UTC", "worker_type_id"=>"#{old_worker_type.id}"})
      expect(employee.emp_deltas.last.after).to eq({"last_name"=>"Goodall", "start_date"=>"2017-01-01 00:00:00 UTC", "worker_type_id"=>"#{worker_type.id}"})
      expect(employee.profiles.active.profile_status).to eq("active")
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.profiles.terminated).to eq(profile)
      expect(employee.profiles.terminated.profile_status).to eq("terminated")
      expect(employee.profiles.terminated.worker_type).to eq(old_worker_type)
    end
  end

  context "sync existing employee with department profile change" do
    let!(:old_department) { FactoryGirl.create(:department) }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      adp_assoc_oid: "AAABBBCCCDDD",
      adp_employee_id: "123456",
      company: "OpenTable, Inc.",
      department: old_department,
      job_title: job_title,
      location: location,
      manager_id: "654321",
      profile_status: "active",
      start_date: Date.new(2017, 01, 01),
      worker_type: worker_type )}

    it "should update current profile and send email" do
      expect(EmployeeWorker).to receive(:perform_async)

      w_hash = parser.gen_worker_hash(json["workers"][0])
      profiler = EmployeeProfile.new
      profiler.update_employee(employee, w_hash)

      expect(Employee.count).to eq(1)
      expect(employee.profiles.count).to eq(1)
      expect(employee.emp_deltas.count).to eq(1)
      expect(employee.emp_deltas.last.before).to eq({"department_id"=>"#{old_department.id}"})
      expect(employee.emp_deltas.last.after).to eq({"department_id"=>"#{department.id}"})
      expect(employee.profiles.active.profile_status).to eq("active")
      expect(employee.department).to eq(department)
    end
  end

  context "create from new employee event" do
    let(:hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_hire_event.json") }
    let!(:new_hire_wt) { FactoryGirl.create(:worker_type, code: "OLFR")}

    it "should create a new employee record" do
      event = FactoryGirl.create(:adp_event,
        status: "New",
        json: hire_json)
      profiler = EmployeeProfile.new
      profiler.new_employee(event)
      new_employee = Employee.reorder(:created_at).last

      expect(Employee.count).to eq(2)
      expect(new_employee.first_name).to eq("Hire")
      expect(new_employee.last_name).to eq("Testone")
      expect(new_employee.status).to eq("created")
      expect(new_employee.hire_date).to eq(Date.new(2017, 1, 23))
      expect(new_employee.contract_end_date).to eq(nil)
      expect(new_employee.home_state).to eq("MA")
      expect(new_employee.worker_type.code).to eq("OLFR")
      expect(new_employee.business_card_title).to eq("Account Executive")
      expect(new_employee.profiles.count).to eq(1)
      expect(new_employee.profiles.last.adp_employee_id).to eq("if0rcdig4")
      expect(new_employee.profiles.last.worker_type.code).to eq("OLFR")
      expect(new_employee.profiles.last.profile_status).to eq("pending")
      expect(new_employee.profiles.last.start_date).to eq(Date.new(2017, 1, 23))
      expect(new_employee.profiles.last.end_date).to eq(nil)
    end
  end

  context "build employee helper" do
    let(:hire_json) { File.read(Rails.root.to_s+"/spec/fixtures/adp_hire_event.json") }
    let!(:new_hire_wt) { FactoryGirl.create(:worker_type, code: "OLFR")}

    it "should build but not persist employee and profile" do
      event = FactoryGirl.create(:adp_event,
        status: "New",
        json: hire_json)
      profiler = EmployeeProfile.new
      employee = profiler.build_employee(event)

      expect(employee.persisted?).to eq(false)
      expect(Employee.count).to eq(1)
      expect(employee.first_name).to eq("Hire")
      expect(employee.last_name).to eq("Testone")
      expect(employee.status).to eq("active")
      expect(employee.hire_date).to eq(Date.new(2017, 1, 23))
      expect(employee.worker_type.code).to eq("OLFR")
    end
  end
end
