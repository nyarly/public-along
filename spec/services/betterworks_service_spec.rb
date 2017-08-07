require 'rails_helper'

describe BetterworksService, type: :service do

  before :each do
    Dir["tmp/betterworks/*"].each do |f|
      File.delete(f)
    end

    dirname = 'tmp/betterworks'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end

  after :each do
    Dir["tmp/betterworks/*"].each do |f|
      File.delete(f)
    end
  end

  describe "get betterworks users" do
    let(:service) { BetterworksService.new }
    let(:ftr_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTR",
      kind: "Regular") }
    let(:ptr_worker_type) { FactoryGirl.create(:worker_type,
      code: "PTR",
      kind: "Regular") }
    let(:temp_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTT",
      kind: "Temporary") }

    it "should scope only regular employees" do
      ftr_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Active",
        hire_date: 1.year.ago)
      ptr_emp = FactoryGirl.create(:employee,
        worker_type: ptr_worker_type,
        status: "Active",
        hire_date: 1.year.ago)
      temp = FactoryGirl.create(:employee,
        worker_type: temp_worker_type,
        status: "Active",
        hire_date: 1.year.ago)

      expect(service.betterworks_users.count).to eq(2)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).to include(ptr_emp)
      expect(service.betterworks_users).not_to include(temp)
    end

    it "should not include employees who have not started" do
      ftr_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Active",
        hire_date: 1.year.ago)
      ftr_new_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Pending",
        hire_date: Date.today + 2.weeks)

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_new_emp)
    end

    it "should not include old terminated employees" do
      ftr_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Active",
        hire_date: 1.year.ago)
      ftr_termed_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Terminated",
        hire_date: 1.year.ago,
        termination_date: Date.new(2017, 5, 4))

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_termed_emp)
    end

    it "should include terminated workers after the product launch" do
      scoped_term = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        hire_date: 1.year.ago,
        termination_date: Date.new(2017, 7, 25))

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(scoped_term)
    end

    it "should include workers on leave" do
      leave = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        hire_date: 1.year.ago,
        leave_start_date: 1.month.ago,
        status: "Inactive")

      expect(service.betterworks_users).to include(leave)
    end
  end

  describe "generate betterworks user csv" do
    let(:service) { BetterworksService.new }
    let(:ftr_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTR",
      kind: "Regular") }
    let(:ptr_worker_type) { FactoryGirl.create(:worker_type,
      code: "PTR",
      kind: "Regular") }
    let(:department) { FactoryGirl.create(:department,
      name: "Infrastructure Engineering") }
    let(:job_title) { FactoryGirl.create(:job_title,
      name: "Engineer") }
    let!(:emp) { FactoryGirl.create(:employee,
      email: "hgolightly@example.com",
      first_name: "Holly",
      last_name: "Golightly",
      employee_id: "123A",
      department: department,
      job_title: job_title,
      termination_date: nil,
      hire_date: 1.month.ago,
      status: "Active",
      worker_type: ftr_worker_type,
      manager_id: nil )}
    let!(:term_emp) { FactoryGirl.create(:employee,
      email: "fparson@example.com",
      first_name: "Fred",
      last_name: "Parson",
      employee_id: "123B",
      department: department,
      job_title: job_title,
      hire_date: 1.year.ago,
      worker_type: ftr_worker_type,
      manager_id: emp.employee_id,
      termination_date: Date.new(2017, 7, 24)
      )}
    let!(:leave_emp) { FactoryGirl.create(:employee,
      email: "dwallace@example.com",
      first_name: "David",
      last_name: "Wallace",
      employee_id: "123C",
      department: department,
      job_title: job_title,
      hire_date: 1.year.ago,
      status: "Inactive",
      worker_type: ptr_worker_type,
      manager_id: emp.employee_id,
      leave_start_date: 1.month.ago)}

    let(:filepath) { Rails.root.to_s+"/tmp/betterworks/OT_Betterworks_users_#{DateTime.now.strftime('%Y%m%d')}.csv" }
    let(:csv) {
      <<-EOS.strip_heredoc
      email,employee_id,first_name,last_name,department_name,title,location,deactivation_date,on_leave,manager_id,manager_email
      #{emp.email},#{emp.employee_id},#{emp.first_name},#{emp.last_name},#{emp.department.name},#{emp.job_title.name},#{emp.location.name},,false,"",""
      #{term_emp.email},#{term_emp.employee_id},#{term_emp.first_name},#{term_emp.last_name},#{term_emp.department.name},#{term_emp.job_title.name},#{term_emp.location.name},#{DateTime.now.strftime('%m/%d/%Y')},false,#{term_emp.manager_id},#{emp.email}
      #{leave_emp.email},#{leave_emp.employee_id},#{leave_emp.first_name},#{leave_emp.last_name},#{leave_emp.department.name},#{leave_emp.job_title.name},#{emp.location.name},,true,#{leave_emp.manager_id},#{emp.email}
      EOS
    }

    it "should output csv string" do
      Timecop.freeze(Time.new(2017, 7, 24, 5, 0, 0, "-07:00"))

      service.generate_employee_csv
      expect(File.read(filepath)).to eq(csv)
    end
  end

end
