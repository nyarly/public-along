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
        hire_date: Date.new(2017, 1, 1))
      ptr_emp = FactoryGirl.create(:employee,
        worker_type: ptr_worker_type,
        status: "Active",
        hire_date: Date.new(2017, 1, 1))
      temp = FactoryGirl.create(:employee,
        worker_type: temp_worker_type,
        status: "Active",
        hire_date: Date.new(2017, 1, 1))

      expect(service.betterworks_users.count).to eq(2)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).to include(ptr_emp)
      expect(service.betterworks_users).not_to include(temp)
    end

    it "should not include employees who have not started" do
      ftr_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Active",
        hire_date: Date.new(2017, 1, 1))
      ftr_new_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Pending",
        hire_date: Date.today + 2.weeks)

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_new_emp)
    end

    it "should not include terminated employees" do
      ftr_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Active",
        hire_date: Date.new(2017, 1, 1))
      ftr_termed_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        status: "Terminated",
        hire_date: Date.new(2017, 1, 1),
        termination_date: Date.new(2017, 5, 4))

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_termed_emp)
    end
  end

  describe "generate betterworks user csv" do
    let(:service) { BetterworksService.new }
    let(:ftr_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTR",
      kind: "Regular") }
    let(:department) { FactoryGirl.create(:department,
      name: "Infrastructure Engineering") }
    let(:job_title) { FactoryGirl.create(:job_title,
      name: "Engineer") }
    let!(:emp) { FactoryGirl.create(:employee,
      email: "hgolightly@example.com",
      first_name: "Holly",
      last_name: "Golightly",
      department: department,
      job_title: job_title,
      termination_date: nil,
      hire_date: 1.month.ago,
      status: "Active",
      worker_type: ftr_worker_type) }
    let!(:term_emp) { FactoryGirl.create(:employee,
      email: "fparson@example.com",
      first_name: "Fred",
      last_name: "Parson",
      department: department,
      job_title: job_title,
      hire_date: 1.year.ago,
      status: "Active",
      worker_type: ftr_worker_type,
      manager_id: emp.employee_id,
      termination_date: Date.today
      )}
    let(:filepath) { Rails.root.to_s+"/tmp/betterworks/OT_Betterworks_users_#{DateTime.now.strftime('%Y%m%d')}.csv" }
    let(:csv) {
      <<-EOS.strip_heredoc
      email,first_name,last_name,department_name,title,manager_email,deactivation_date
      #{term_emp.email},#{term_emp.first_name},#{term_emp.last_name},#{term_emp.department.name},#{term_emp.job_title.name},#{emp.email},#{DateTime.now.strftime('%m/%d/%Y')}
      #{emp.email},#{emp.first_name},#{emp.last_name},#{emp.department.name},#{emp.job_title.name},"",
      EOS
    }

    it "should output csv string" do
      service.generate_employee_csv
      expect(File.read(filepath)).to eq(csv)
    end
  end

end
