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
    Timecop.return
  end

  describe "get betterworks users" do
    let(:service) { BetterworksService.new }
    let(:ftr_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTR",
      kind: "Regular") }
    let(:ptr_worker_type) { FactoryGirl.create(:worker_type,
      code: "PTR",
      kind: "Regular") }
    let!(:temp_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTT",
      kind: "Temporary") }
    let(:contractor_worker_type) { FactoryGirl.create(:worker_type,
      code: "CONT",
      kind: "Contractor") }

    it "should scope only regular employees" do
      ftr_emp = FactoryGirl.create(:employee,
        hire_date: 1.year.ago)
      ftr_prof = FactoryGirl.create(:active_profile,
        employee: ftr_emp,
        worker_type: ftr_worker_type)
      ptr_emp = FactoryGirl.create(:employee,
        hire_date: 1.year.ago)
      ptr_prf = FactoryGirl.create(:active_profile,
        employee: ptr_emp,
        worker_type: ptr_worker_type)
      temp = FactoryGirl.create(:employee,
        hire_date: 1.year.ago)
      temp_prf = FactoryGirl.create(:active_profile,
        employee: temp,
        worker_type: temp_worker_type)
      rehired_worker = FactoryGirl.create(:pending_employee,
        hire_date: 2.years.ago)
      rehired_profile = FactoryGirl.create(:profile,
        employee: rehired_worker,
        worker_type: ftr_worker_type)
      rehired_old_prof = FactoryGirl.create(:terminated_profile,
        worker_type: ftr_worker_type,
        employee: rehired_worker)

      expect(service.betterworks_users.count).to eq(3)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).to include(ptr_emp)
      expect(service.betterworks_users).to include(rehired_worker)
      expect(service.betterworks_users).not_to include(temp)
    end

    it "should not include employees who have not started" do
      ftr_emp = FactoryGirl.create(:employee,
        hire_date: 1.year.ago)
      ftr_prof = FactoryGirl.create(:profile,
        employee: ftr_emp,
        worker_type: ftr_worker_type)
      ftr_new_emp = FactoryGirl.create(:employee,
        hire_date: Date.today + 2.weeks)
      ftr_prof = FactoryGirl.create(:profile,
        employee: ftr_new_emp,
        worker_type: ftr_worker_type)

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_new_emp)
    end

    it "should not include old terminated employees" do
      ftr_emp = FactoryGirl.create(:active_employee,
        hire_date: 1.year.ago)
      ftr_prof = FactoryGirl.create(:active_profile,
        employee: ftr_emp,
        worker_type: ftr_worker_type)
      ftr_termed_emp = FactoryGirl.create(:terminated_employee,
        hire_date: 1.year.ago,
        termination_date: Date.new(2017, 5, 4))
      ftr_termed_prof = FactoryGirl.create(:terminated_profile,
        employee: ftr_termed_emp,
        end_date: Date.new(2017, 5, 1))

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_termed_emp)
    end

    it "should include terminated workers after the product launch" do
      scoped_term = FactoryGirl.create(:employee,
        status: "terminated",
        hire_date: 1.year.ago,
        termination_date: Date.new(2017, 7, 25))
      ftr_prof = FactoryGirl.create(:profile,
        profile_status: "terminated",
        end_date: Date.new(2017, 7, 25),
        employee: scoped_term,
        worker_type: ftr_worker_type)

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(scoped_term)
    end

    it "should include workers on leave" do
      leave = FactoryGirl.create(:leave_employee,
        hire_date: 1.year.ago,
        leave_start_date: 1.month.ago)
      leave_prof = FactoryGirl.create(:profile,
        employee: leave,
        profile_status: "leave",
        worker_type: ftr_worker_type)

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
    let(:contractor_worker_type) { FactoryGirl.create(:worker_type,
      code: "CONT",
      kind: "Contractor") }
    let(:department) { FactoryGirl.create(:department,
      name: "Infrastructure Engineering") }
    let(:job_title) { FactoryGirl.create(:job_title,
      name: "Engineer") }
    let!(:emp) { FactoryGirl.create(:employee,
      status: "active",
      email: "hgolightly@example.com",
      first_name: "Holly",
      last_name: "Golightly",
      termination_date: nil,
      hire_date: Date.new(2016, 1, 1)) }
    let!(:emp_prof) { FactoryGirl.create(:active_profile,
      employee: emp,
      adp_employee_id: "123A",
      start_date: 1.month.ago,
      department: department,
      job_title: job_title,
      worker_type: ftr_worker_type) }
    let!(:old_emp_prof) { FactoryGirl.create(:terminated_profile,
      employee: emp,
      adp_employee_id: "123A",
      department: department,
      job_title: job_title,
      worker_type: contractor_worker_type,
      start_date: Date.new(2017, 1, 1),
      end_date: 1.month.ago)}
    let!(:term_emp) { FactoryGirl.create(:employee,
      status: "terminated",
      email: "fparson@example.com",
      first_name: "Fred",
      last_name: "Parson",
      manager: emp,
      hire_date: 1.year.ago,
      termination_date: Date.new(2017, 7, 24)) }
    let!(:term_emp_prof) { FactoryGirl.create(:terminated_profile,
      employee: term_emp,
      profile_status: "terminated",
      adp_employee_id: "123B",
      department: department,
      job_title: job_title,
      worker_type: ftr_worker_type,
      start_date: 1.year.ago,
      end_date: Date.new(2017, 7, 24)) }
    let!(:leave_emp) { FactoryGirl.create(:employee,
      status: "inactive",
      email: "dwallace@example.com",
      first_name: "David",
      last_name: "Wallace",
      hire_date: 1.year.ago,
      manager: emp,
      leave_start_date: 1.month.ago) }
    let!(:leave_emp_prof) { FactoryGirl.create(:profile,
      employee: leave_emp,
      profile_status: "leave",
      adp_employee_id: "123C",
      department: department,
      job_title: job_title,
      worker_type: ptr_worker_type) }
    let!(:rehired_worker) { FactoryGirl.create(:employee,
      status: "pending",
      email: "cklein@example.com",
      first_name: "Calvin",
      last_name: "Klein",
      hire_date: 2.years.ago) }
    let!(:rehired_old_prof) { FactoryGirl.create(:terminated_profile,
      start_date: 2.years.ago,
      end_date: Date.new(2017, 7, 24),
      worker_type: ftr_worker_type,
      employee: rehired_worker,
      adp_employee_id: "222bbb") }
    let!(:rehired_profile) { FactoryGirl.create(:profile,
      start_date: Date.new(2017, 9, 1),
      employee: rehired_worker,
      worker_type: ftr_worker_type,
      adp_employee_id: "111aaa") }

    let(:filepath) { Rails.root.to_s+"/tmp/betterworks/OT_Betterworks_users_#{DateTime.now.strftime('%Y%m%d')}.csv" }
    let(:csv) {
      <<-EOS.strip_heredoc
      email,employee_id,first_name,last_name,department_name,title,location,deactivation_date,on_leave,manager_id,manager_email
      #{emp.email},#{emp.employee_id},#{emp.first_name},#{emp.last_name},#{emp.department.name},#{emp.job_title.name},#{emp.location.name},,false,"",""
      #{rehired_worker.email},#{rehired_old_prof.adp_employee_id},#{rehired_worker.first_name},#{rehired_worker.last_name},#{rehired_old_prof.department.name},#{rehired_old_prof.job_title.name},#{rehired_old_prof.location.name},#{rehired_old_prof.end_date.strftime('%m/%d/%Y')},false,"",""
      #{term_emp.email},#{term_emp.employee_id},#{term_emp.first_name},#{term_emp.last_name},#{term_emp.department.name},#{term_emp.job_title.name},#{term_emp.location.name},#{DateTime.now.strftime('%m/%d/%Y')},false,"123A",#{term_emp.manager.email}
      #{leave_emp.email},#{leave_emp.employee_id},#{leave_emp.first_name},#{leave_emp.last_name},#{leave_emp.department.name},#{leave_emp.job_title.name},#{leave_emp.location.name},,true,"123A",#{leave_emp.manager.email}
      EOS
    }
    let(:future_csv) {
      <<-EOS.strip_heredoc
      email,employee_id,first_name,last_name,department_name,title,location,deactivation_date,on_leave,manager_id,manager_email
      #{emp.email},#{emp.employee_id},#{emp.first_name},#{emp.last_name},#{emp.department.name},#{emp.job_title.name},#{emp.location.name},,false,"",""
      #{rehired_worker.email},#{rehired_profile.adp_employee_id},#{rehired_worker.first_name},#{rehired_worker.last_name},#{rehired_profile.department.name},#{rehired_profile.job_title.name},#{rehired_profile.location.name},,false,"",""
      #{term_emp.email},#{term_emp.employee_id},#{term_emp.first_name},#{term_emp.last_name},#{term_emp.department.name},#{term_emp.job_title.name},#{term_emp.location.name},#{term_emp.termination_date.strftime('%m/%d/%Y')},false,"123A",#{term_emp.manager.email}
      #{leave_emp.email},#{leave_emp.employee_id},#{leave_emp.first_name},#{leave_emp.last_name},#{leave_emp.department.name},#{leave_emp.job_title.name},#{leave_emp.location.name},,true,"123A",#{leave_emp.manager.email}
      EOS
    }

    it "should output csv string" do
      Timecop.freeze(Time.new(2017, 7, 24, 5, 0, 0, "-07:00"))

      service.generate_employee_csv
      expect(File.read(filepath)).to eq(csv)
    end

    it "should output csv string after rehired worker starts new position" do
      Timecop.freeze(Time.new(2017, 9, 3, 0, 0, 0, "-07:00"))
      rehired_worker.assign_attributes(status: "active")
      rehired_profile.assign_attributes(profile_status: "active")
      term_emp_prof.assign_attributes(profile_status: "terminated")
      term_emp.assign_attributes(status: "terminated")
      rehired_worker.save && rehired_profile.save
      term_emp.save && term_emp_prof.save

      service.generate_employee_csv
      expect(File.read(filepath)).to eq(future_csv)
    end
  end

end
