require 'rails_helper'
require 'aasm/rspec'

describe Employee, type: :model do

  let(:manager) { FactoryGirl.create(:regular_employee,
    first_name: "Alex",
    last_name: "Trebek",
    sam_account_name: "atrebek",
    hire_date: 5.years.ago,
    ad_updated_at: 2.years.ago) }

  describe "state machine" do
    let!(:regular_sp)      { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
    let(:employee)         { FactoryGirl.create(:employee) }
    let!(:profile)         { FactoryGirl.create(:profile, employee: employee) }
    let!(:active_employee) { FactoryGirl.create(:active_employee) }
    let!(:active_profile)  { FactoryGirl.create(:active_profile, employee: active_employee) }
    let!(:pending_employee){ FactoryGirl.create(:pending_employee) }
    let!(:pending_profile) { FactoryGirl.create(:profile, employee: pending_employee) }
    let!(:leave_employee)  { FactoryGirl.create(:leave_employee) }
    let!(:leave_profile)   { FactoryGirl.create(:leave_profile, employee: leave_employee) }
    let!(:termed_employee) { FactoryGirl.create(:terminated_employee) }
    let!(:termed_profile)  { FactoryGirl.create(:terminated_profile, employee: termed_employee) }
    let!(:new_profile)     { FactoryGirl.create(:profile, employee: termed_employee) }
    let(:ad)               { double(ActiveDirectoryService) }
    let(:mailer)           { double(ManagerMailer) }
    let(:os)               { double(OffboardingService) }
    let(:sas)              { double(SecAccessService) }

    it "should initialize as created" do
      expect(employee).to have_state(:created)
      expect(employee).to allow_event(:hire)
      expect(employee).to allow_transition_to(:pending)
      expect(employee).not_to allow_transition_to(:active)
      expect(employee).not_to allow_transition_to(:terminated)
      expect(employee).not_to allow_transition_to(:inactive)
      expect(employee).not_to allow_event(:rehire)
      expect(employee).not_to allow_event(:activate)
      expect(employee).not_to allow_event(:start_leave)
      expect(employee).not_to allow_event(:end_leave)
      expect(employee).not_to allow_event(:terminate)

      expect(employee).to have_state(:none).on(:request_status)
      expect(employee).to allow_event(:wait).on(:request_status)
      expect(employee).to allow_transition_to(:waiting).on(:request_status)
      expect(employee).not_to allow_event(:clear).on(:request_status)

      expect(employee.profiles.count).to eq(1)
      expect(employee.current_profile.profile_status).to eq("pending")
    end

    it "employee.hire! should create accounts and set as pending" do
      expect(SecAccessService).to receive(:new).and_return(sas)
      expect(sas).to receive(:apply_ad_permissions)
      expect(pending_employee).to receive(:create_active_directory_account).and_return(ad)
      expect(pending_employee).to receive(:check_manager).and_return(true)
      expect(EmployeeWorker).to receive(:perform_async)
      expect(pending_employee).to transition_from(:created).to(:pending).on_event(:hire)
      expect(pending_employee).to have_state(:pending)
      expect(pending_employee).not_to allow_transition_to(:created)
      expect(pending_employee).not_to allow_transition_to(:terminated)
      expect(pending_employee).not_to allow_transition_to(:inactive)
      expect(pending_employee).not_to allow_event(:rehire)
      expect(pending_employee).not_to allow_event(:start_leave)
      expect(pending_employee).not_to allow_event(:end_leave)
      expect(pending_employee).not_to allow_event(:terminate)

      expect(pending_employee).to have_state(:waiting).on(:request_status)
      expect(pending_employee).to allow_event(:complete).on(:request_status)

      expect(pending_employee.profiles.count).to eq(1)
      expect(pending_employee.current_profile.profile_status).to eq("pending")
    end

    it "should allow employee to activate if onboarding is complete" do
      pending_employee.request_status = "completed"
      expect(pending_employee).to allow_event(:activate)
      expect(pending_employee).to allow_transition_to(:active)
    end

    it "employee.activate! should make employee active" do
      employee.request_status = "completed"

      expect(employee).to receive(:activate_active_directory_account).and_return(ad)
      expect(employee).to transition_from(:pending).to(:active).on_event(:activate)
      expect(employee).to have_state(:active)
      expect(employee).to allow_event(:start_leave)
      expect(employee).to allow_event(:terminate)
      expect(employee).to allow_transition_to(:inactive)
      expect(employee).to allow_transition_to(:terminated)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:pending)
      expect(employee).not_to allow_event(:hire)
      expect(employee).not_to allow_event(:rehire)
      expect(employee).not_to allow_event(:activate)

      expect(employee).to have_state(:none).on(:request_status)

      expect(employee.profiles.count).to eq(1)
      expect(employee.current_profile.profile_status).to eq("active")
    end

    it "should not activate employee if onboarding form is not complete" do
      employee.status = "pending"
      employee.request_status = "waiting"

      employee.activate!

      expect(employee).not_to transition_from(:pending).to(:active).on_event(:activate)
      expect(employee).to have_state(:pending)
      expect(employee).not_to allow_event(:terminate)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:active)
      expect(employee).not_to allow_event(:hire)
      expect(employee).not_to allow_event(:rehire)
      expect(employee).not_to allow_event(:activate)

      expect(employee).to have_state(:waiting).on(:request_status)

      expect(employee.profiles.count).to eq(1)
      expect(employee.current_profile.profile_status).to eq("pending")
    end

    it "employee.start_leave! should put employee on leave" do
      expect(active_employee).to receive(:deactivate_active_directory_account).and_return(ad)
      expect(active_employee).to transition_from(:active).to(:inactive).on_event(:start_leave)
      expect(active_employee).to have_state(:inactive)
      expect(active_employee).to allow_event(:activate)
      expect(active_employee).to allow_transition_to(:active)
      expect(active_employee).not_to allow_transition_to(:created)
      expect(active_employee).not_to allow_transition_to(:pending)
      expect(active_employee).not_to allow_transition_to(:terminated)
      expect(active_employee).not_to allow_event(:hire)
      expect(active_employee).not_to allow_event(:rehire)
      expect(active_employee).not_to allow_event(:terminate)
      expect(active_employee).not_to allow_event(:start_leave)

      expect(active_employee).to have_state(:none).on(:request_status)

      expect(active_employee.current_profile.profile_status).to eq("leave")
    end

    it "employee.activate! should return employee from leave" do
      # expect(leave_employee).to receive(:activate_active_directory_account).and_return(ad)
      expect(leave_employee).to transition_from(:inactive).to(:active).on_event(:activate)
      expect(leave_employee).to have_state(:active)
      expect(leave_employee).to allow_event(:start_leave)
      expect(leave_employee).to allow_event(:terminate)
      expect(leave_employee).to allow_transition_to(:inactive)
      expect(leave_employee).to allow_transition_to(:terminated)
      expect(leave_employee).not_to allow_transition_to(:created)
      expect(leave_employee).not_to allow_transition_to(:pending)
      expect(leave_employee).not_to allow_event(:hire)
      expect(leave_employee).not_to allow_event(:rehire)
      expect(leave_employee).not_to allow_event(:activate)

      expect(leave_employee).to have_state(:none).on(:request_status)
    end

    it "employee.terminate! should terminate employee" do
      expect(active_employee).to receive(:deactivate_active_directory_account).and_return(ad)
      expect(active_employee).to receive(:offboard).and_return(os)
      expect(active_employee).to transition_from(:active).to(:terminated).on_event(:terminate)
      expect(active_employee).to have_state(:terminated)
      expect(active_employee).to allow_event(:rehire)
      expect(active_employee).to allow_transition_to(:pending)
      expect(active_employee).not_to allow_transition_to(:created)
      expect(active_employee).not_to allow_transition_to(:inactive)
      expect(active_employee).not_to allow_transition_to(:active)
      expect(active_employee).not_to allow_event(:hire)
      expect(active_employee).not_to allow_event(:activate)
      expect(active_employee).not_to allow_event(:terminate)
      expect(active_employee).not_to allow_event(:start_leave)

      expect(active_employee).to have_state(:none).on(:request_status)

      expect(active_employee.current_profile.profile_status).to eq("terminated")
    end

    it "employee.rehire! should kick off rehire process" do
      expect(SecAccessService).to receive(:new).and_return(sas)
      expect(sas).to receive(:apply_ad_permissions)
      expect(termed_employee).to receive(:update_active_directory_account).and_return(ad)
      expect(termed_employee).to receive(:check_manager).and_return(true)
      expect(EmployeeWorker).to receive(:perform_async)
      expect(termed_employee).to transition_from(:terminated).to(:pending).on_event(:rehire)
      expect(termed_employee).to have_state(:pending)
      expect(termed_employee).not_to allow_transition_to(:active)
      expect(termed_employee).not_to allow_transition_to(:terminated)
      expect(termed_employee).not_to allow_transition_to(:created)
      expect(termed_employee).not_to allow_transition_to(:inactive)
      expect(termed_employee).not_to allow_event(:activate)
      expect(termed_employee).not_to allow_event(:hire)
      expect(termed_employee).not_to allow_event(:start_leave)
      expect(termed_employee).not_to allow_event(:terminate)

      expect(termed_employee).to have_state(:waiting).on(:request_status)

      expect(termed_employee.profiles.first.profile_status).to eq("terminated")
      expect(termed_employee.current_profile.profile_status).to eq("pending")
    end
  end

  context "with a regular employee" do
    let(:employee) { FactoryGirl.create(:employee,
      first_name: "Bob",
      last_name: "Barker",
      sam_account_name: "bbarker",
      hire_date: 1.year.ago,
      ad_updated_at: 1.hour.ago) }

    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
      employee: employee,
      manager_id: manager.employee_id) }

    it "should meet validations" do
      expect(employee).to be_valid

      expect(employee).to_not allow_value(nil).for(:first_name)
      expect(employee).to_not allow_value(nil).for(:last_name)
      expect(employee).to_not allow_value(nil).for(:hire_date)
      expect(employee).to     allow_value(nil).for(:email)
    end

    it "should strip whitespaces" do
      emp = FactoryGirl.create(:employee, first_name: " Walter", last_name: " Sobchak ")

      expect(emp.first_name).to eq("Walter")
      expect(emp.last_name).to eq("Sobchak")
    end

    it "should downcase emails" do
      emp = FactoryGirl.create(:employee, email: "WSobchak@opentable.com")

      expect(emp.email).to eq("wsobchak@opentable.com")
    end

    it "should scope managers" do
      mgr = FactoryGirl.create(:regular_employee)
      emp = FactoryGirl.create(:regular_employee)

      sp = FactoryGirl.create(:security_profile,
        name: "Basic Manager")
      et = FactoryGirl.create(:emp_transaction,
        employee_id: mgr.id)
      esp = FactoryGirl.create(:emp_sec_profile,
        security_profile_id: sp.id,
        emp_transaction_id: et.id)

      expect(Employee.managers).to include(mgr)
      expect(Employee.managers).to_not include(emp)
    end

    it "should scope the correct leave return group" do
      activation_group = [
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.yesterday),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.today),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.tomorrow)
      ]
      non_activation_group = [
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 1.week.ago),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 2.days.ago),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 2.days.from_now),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 1.week.from_now)
      ]

      expect(Employee.leave_return_group).to match_array(activation_group)
      expect(Employee.leave_return_group).to_not include(non_activation_group)
    end

    it "should scope the correct deactivation group" do
      deactivation_group = [
        FactoryGirl.create(:employee, :contract_end_date => Date.yesterday),
        FactoryGirl.create(:employee, :contract_end_date => Date.today),
        FactoryGirl.create(:employee, :contract_end_date => Date.tomorrow),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => Date.yesterday),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => Date.today),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => Date.tomorrow)
      ]
      non_deactivation_group = [
        FactoryGirl.create(:employee, :contract_end_date => 1.week.ago),
        FactoryGirl.create(:employee, :contract_end_date => 2.days.ago),
        FactoryGirl.create(:employee, :contract_end_date => 2.days.from_now),
        FactoryGirl.create(:employee, :contract_end_date => 1.week.from_now),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 1.week.ago),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 2.days.ago),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 2.days.from_now),
        FactoryGirl.create(:employee, :contract_end_date => 1.year.from_now, :leave_start_date => 1.week.from_now)
      ]

      expect(Employee.deactivation_group).to match_array(deactivation_group)
      expect(Employee.deactivation_group).to_not include(non_deactivation_group)
    end

    it "should check if the employee is contingent" do
      reg_emp = FactoryGirl.create(:regular_employee)
      contingent_emp = FactoryGirl.create(:contract_worker)

      expect(reg_emp.is_contingent_worker?).to eq(false)
      expect(contingent_emp.is_contingent_worker?).to eq(true)
    end

    it "should scope the offboarding groups" do
      offboarding_group = [
        FactoryGirl.create(:employee, :termination_date => Date.today),
        FactoryGirl.create(:employee, :termination_date => Date.today - 1.day),
        FactoryGirl.create(:employee, :termination_date => Date.today - 1.week)
      ]
      non_offboarding_group = [
        FactoryGirl.create(:employee, :termination_date => Date.today + 1.day),
        FactoryGirl.create(:employee, :termination_date => Date.today + 5.days),
        FactoryGirl.create(:employee, :termination_date => Date.today + 1.week),
        FactoryGirl.create(:employee, :termination_date => Date.today - 3.weeks)
      ]

      expect(Employee.offboarding_report_group).to match_array(offboarding_group)
      expect(Employee.offboarding_report_group).to_not include(non_offboarding_group)
    end

    it "should check onboarding is complete" do
      completed = FactoryGirl.create(:employee)
      emp_trans_1 = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: completed.id)
      onboarding_info = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans_1.id)

      not_completed = FactoryGirl.create(:employee, request_status: "waiting")

      expect(completed.onboarded?).to eq(true)
      expect(not_completed.onboarded?).to eq(false)
    end

    it "should check offboarding is complete" do
      completed = FactoryGirl.create(:employee)
      emp_trans_1 = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: completed.id)
      offboarding_info = FactoryGirl.create(:offboarding_info,
        emp_transaction_id: emp_trans_1.id)

      not_completed = FactoryGirl.create(:employee)

      expect(completed.offboarding_complete?).to eq(true)
      expect(not_completed.offboarding_complete?).to eq(false)
    end

    it "should find active/revoked security profiles" do
      emp = FactoryGirl.create(:regular_employee)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      user = FactoryGirl.create(:user)
      emp_transaction = FactoryGirl.create(:onboarding_emp_transaction,
        employee_id: emp.id)
      revoking_transaction = FactoryGirl.create(:emp_transaction,
        employee_id: emp.id,
        user_id: user.id,
        kind: "Security Access")
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        security_profile_id: sec_prof_1.id,
        emp_transaction_id: emp_transaction.id,
        revoking_transaction_id: revoking_transaction.id)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile,
        security_profile_id: sec_prof_2.id,
        emp_transaction_id: emp_transaction.id,
        revoking_transaction_id: nil)

      expect(emp.active_security_profiles).to include(sec_prof_2)
      expect(emp.revoked_security_profiles).to include(sec_prof_1)
    end

    it "should group security profiles that do not belong to current department" do
      department = FactoryGirl.create(:department)
      employee = FactoryGirl.create(:employee)
      profile = FactoryGirl.create(:profile,
        employee: employee,
        department: department)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      emp_trans = FactoryGirl.create(:emp_transaction, employee_id: employee.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof_1.id,
        revoking_transaction_id: nil)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof_2.id,
        revoking_transaction_id: nil)
      dept_sec_prof_1 = FactoryGirl.create(:dept_sec_prof,
        department_id: department.id,
        security_profile_id: sec_prof_1.id)

      expect(employee.security_profiles_to_revoke).to include(sec_prof_2)
      expect(employee.security_profiles_to_revoke).to_not include(sec_prof_1)
    end

    it "should calculate an onboarding due date according to location" do
      emp_1 = FactoryGirl.create(:pending_employee,
        hire_date: Date.new(2016, 7, 25, 2))
      prof_1 = FactoryGirl.create(:profile,
        employee: emp_1,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("San Francisco Headquarters"))
      emp_2 = FactoryGirl.create(:pending_employee,
        hire_date: Date.new(2016, 7, 25, 2))
      prof_2 = FactoryGirl.create(:profile,
        employee: emp_2,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("London Office"))
      emp_3 = FactoryGirl.create(:pending_employee,
        hire_date: Date.new(2016, 7, 25, 2))
      prof_3 = FactoryGirl.create(:profile,
        employee: emp_3,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("Mumbai Office"))

      expect(emp_1.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_2.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_3.onboarding_due_date).to eq("Jul 11, 2016")
    end

    it "should calculate the onboarding due date for a rehired worker" do
      employee = FactoryGirl.create(:pending_employee,
        hire_date: Date.new(2016, 1, 1))
      old_profile = FactoryGirl.create(:terminated_profile,
        employee: employee,
        start_date: Date.new(2016, 1, 1),
        end_date: Date.new(2017, 1, 1))
      new_profile = FactoryGirl.create(:profile,
        employee: employee,
        start_date: Date.new(2017, 9, 25),
        location: Location.find_by_name("San Francisco Headquarters"))

      expect(employee.onboarding_due_date).to eq("Sep 18, 2017")
      expect(employee.start_date).to eq("Sep 25, 2017")
    end

    it "should calculate the offboarding submission cutoff" do
      past_due_emp = FactoryGirl.create(:employee,
        termination_date: Date.new(2016, 7, 25, 2))
      prof_1 = FactoryGirl.create(:profile,
        employee: past_due_emp,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("San Francisco Headquarters"))

      expect(past_due_emp.offboarding_cutoff).to eq(DateTime.new(2016, 7, 25, 19))
    end

    it "should set the nearest time zone" do
      expect(employee.nearest_time_zone).to eq("Europe/London")
    end
  end

  describe "#check_manager" do
    let(:manager)     { FactoryGirl.create(:regular_employee) }
    let(:mgr_profile) { FactoryGirl.create(:security_profile, name: "Basic Manager") }
    let!(:employee)   { FactoryGirl.create(:employee) }
    let!(:e_profile)  { FactoryGirl.create(:profile,
                        employee: employee,
                        manager_id: manager.employee_id) }
    let(:app)         { FactoryGirl.create(:application) }
    let(:acc_level_1) { FactoryGirl.create(:access_level,
                        application_id: app.id,
                        ad_security_group: nil) }
    let(:acc_level_2) { FactoryGirl.create(:access_level,
                        application_id: app.id,
                        ad_security_group: "distinguished name of AD sec group") }
    let!(:spal_1)     { FactoryGirl.create(:sec_prof_access_level,
                        security_profile_id: mgr_profile.id,
                        access_level_id: acc_level_1.id) }
    let!(:spal_2)     { FactoryGirl.create(:sec_prof_access_level,
                        security_profile_id: mgr_profile.id,
                        access_level_id: acc_level_2.id) }
    let(:sas)         { double(SecAccessService) }

    before :each do
      allow(SecAccessService).to receive(:new).and_return(sas)
    end

    it "should add 'Basic Manager' profile to worker if not present" do
      expect(sas).to receive(:apply_ad_permissions)

      expect{
        employee.check_manager
      }.to change{Employee.managers.include?(manager)}.from(false).to(true)
      expect(manager.emp_sec_profiles.last.security_profile_id).to eq(mgr_profile.id)
      expect(manager.active_security_profiles).to include(mgr_profile)
    end

    it "should apply AD security group if not nil" do
      expect(sas).to receive(:apply_ad_permissions)

      employee.check_manager
    end

    it "should do nothing if worker already has 'Basic Manager' profile" do
      emp_transaction = FactoryGirl.create(:emp_transaction, employee_id: manager.id)
      FactoryGirl.create(:emp_sec_profile,
                         security_profile_id: mgr_profile.id,
                         emp_transaction_id: emp_transaction.id)

      expect(sas).to_not receive(:apply_ad_permissions)

      expect{
        employee.check_manager
      }.to_not change{Employee.managers.include?(manager)}
      expect(Employee.managers.include?(manager)).to eq(true)
    end
  end

  describe "#email_options" do
    it "should return EMAIL_OPTIONS with offboarding option" do
      employee = FactoryGirl.create(:employee, termination_date: Date.new(2018, 3, 6))
      expect(employee.email_options).to eq(Employee::EMAIL_OPTIONS)
    end

    it "should return EMAIL_OPTIONS without offboarding option" do
      employee = FactoryGirl.create(:employee, termination_date: nil)
      expect(employee.email_options).to_not include("Offboarding")
    end
  end

  describe "#onboarding_reminder_group" do
    let!(:due_tomorrow_no_onboard) {FactoryGirl.create(:pending_employee,
      last_name: "Aaaa",
      hire_date: Date.new(2017, 5, 8),
      request_status: "waiting") }
    let!(:due_tomorrow_no_onboard_profile) { FactoryGirl.create(:profile,
      start_date: Date.new(2017, 5, 8),
      employee: due_tomorrow_no_onboard) }

    let!(:due_tomorrow_no_onboard_au) { FactoryGirl.create(:pending_employee,
      last_name: "Bbbb",
      hire_date: Date.new(2017, 5, 15),
      request_status: "waiting") }
    let!(:due_tomorrow_no_onboard_au_profile) { FactoryGirl.create(:profile,
      employee: due_tomorrow_no_onboard_au,
      start_date: Date.new(2017, 5, 15),
      location: Location.find_by_name("Melbourne Office")) }

    let!(:due_tomorrow_w_onboard) { FactoryGirl.create(:pending_employee,
      request_status: "completed",
      hire_date: Date.new(2017, 5, 8)) }
    let!(:due_tomorrow_w_onboard_profile) { FactoryGirl.create(:profile,
      start_date: Date.new(2017, 5, 8),
      employee: due_tomorrow_w_onboard) }
    let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
      kind: "Onboarding",
      employee: due_tomorrow_w_onboard) }
    let!(:onboard) { FactoryGirl.create(:onboarding_info,
      emp_transaction: emp_transaction) }

    let!(:due_later_no_onboard) { FactoryGirl.create(:pending_employee,
      request_status: "waiting",
      hire_date: Date.new(2017, 9, 1)) }
    let!(:due_later_profile) { FactoryGirl.create(:profile,
      start_date: Date.new(2017, 9, 1),
      employee: due_later_no_onboard) }

    it "should return the right employee" do
      Timecop.freeze(Time.new(2017, 4, 29, 16, 00, 0, "+00:00"))
      expect(Employee.onboarding_reminder_group).to eq([due_tomorrow_no_onboard, due_tomorrow_no_onboard_au])
    end
  end

  context "regular worker" do
    let(:manager) { FactoryGirl.create(:regular_employee) }
    let(:employee) { FactoryGirl.create(:employee,
                     first_name: "Bob",
                     last_name: "Barker") }
    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                     employee: employee,
                     manager_id: manager.employee_id) }

    it "should create a cn" do
      expect(employee.cn).to eq("Bob Barker")
    end

    it "should create an fn" do
      expect(employee.fn).to eq("Barker, Bob")
    end

    it "should find the correct ou" do
      expect(employee.ou).to eq("ou=Operations,ou=EU,ou=Users,")
    end

    it "should create a dn" do
      expect(employee.dn).to eq("cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
    end

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to eq("9223372036854775807")
    end

    it "should set the correct address" do
      expect(employee.generated_address).to be_nil
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          dn: "cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "regular worker that has been assigned a sAMAccountName" do
    let(:employee) { FactoryGirl.create(:employee,
                     first_name: "Mary",
                     last_name: "Sue",
                     sam_account_name: "msue") }
    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                     employee: employee,
                     manager_id: manager.employee_id) }

    it "should generate an email using the sAMAccountName" do
      expect(employee.generated_email).to eq("msue@opentable.com")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Mary Sue",
          dn: "cn=Mary Sue,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Mary",
          sn: "Sue",
          sAMAccountName: "msue",
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: "msue@opentable.com",
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "with a contingent worker" do
    let(:employee) { FactoryGirl.create(:employee,
                     first_name: "Sally",
                     last_name: "Field",
                     sam_account_name: "sfield",
                     contract_end_date: 1.month.from_now) }

    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                     employee: employee,
                     manager_id: manager.employee_id) }

    it "should set the correct account expiry" do
      date = employee.contract_end_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
    end

    it "should set the correct address" do
      expect(employee.generated_address).to be_nil
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Sally Field",
          dn: "cn=Sally Field,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Sally",
          sn: "Field",
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "with a contingent worker that has been terminated" do
    let(:cont_wt)  { FactoryGirl.create(:worker_type, :contractor) }
    let(:employee) { FactoryGirl.create(:terminated_employee,
                     first_name: "Bob",
                     last_name: "Barker",
                     contract_end_date: 1.month.from_now,
                     termination_date: 1.day.from_now) }

    let!(:profile) { FactoryGirl.create(:terminated_profile, :with_valid_ou,
                     worker_type: cont_wt,
                     employee: employee,
                     manager_id: manager.employee_id)}

    it "should set the correct account expiry" do
      date = employee.termination_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          dn: "cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end


  context "with a remote worker and one address line" do
    let(:employee) { FactoryGirl.create(:employee,
                     first_name: "Bob",
                     last_name: "Barker",
                     home_address_1: "123 Fake St.",
                     home_city: "Beverly Hills",
                     home_state: "CA",
                     home_zip: "90210") }
    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou, :remote,
                     employee: employee,
                     manager_id: manager.employee_id) }

    it "should set the correct address" do
      expect(employee.generated_address).to eq("123 Fake St.")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          dn: "cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: "123 Fake St.",
          l: "Beverly Hills",
          st: "CA",
          postalCode: "90210",
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end


  context "with a remote worker and two address lines" do
    let(:remote_loc) { FactoryGirl.create(:location, :remote) }
    let(:employee)   { FactoryGirl.create(:employee,
                       first_name: "Bob",
                       last_name: "Barker",
                       home_address_1: "123 Fake St.",
                       home_address_2: "Apt 3G",
                       home_city: "Beverly Hills",
                       home_state: "CA",
                       home_zip: "90210") }
    let!(:profile)   { FactoryGirl.create(:profile,
                       employee: employee,
                       location: remote_loc,
                       department: Department.find_by_name("Customer Support"),
                       manager_id: manager.employee_id) }

    it "should set the correct address" do
      expect(employee.generated_address).to eq("123 Fake St., Apt 3G")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          dn: "cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.job_title.name,
          description: employee.job_title.name,
          employeeType: employee.worker_type.name,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          telephoneNumber: employee.office_phone,
          streetAddress: "123 Fake St., Apt 3G",
          l: "Beverly Hills",
          st: "CA",
          postalCode: "90210",
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "with a terminated worker" do
    let(:employee) { FactoryGirl.create(:employee,
                     termination_date: 2.days.from_now) }
    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                    employee: employee)}

    it "should set the correct account expiry" do
      date = employee.termination_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
    end
  end

  context "when it does not find a location and department ou match" do
    let!(:employee) { FactoryGirl.create(:regular_employee) }

    it "should assign the user to the provisional ou" do
      expect(employee.ou).to eq("ou=Provisional,ou=Users,")
    end
  end

  context "does the worker need a security profile update" do
    let!(:no_update_emp)   { FactoryGirl.create(:active_employee) }
    let!(:emp_delta)       { FactoryGirl.create(:emp_delta,
                             employee: no_update_emp,
                             before: {"department_id"=>"1"},
                             after: {"department_id"=>"1"}) }
    let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
                             employee: no_update_emp,
                             kind: "Security Access") }
    let!(:update_emp)      { FactoryGirl.create(:active_employee) }
    let!(:emp_delta_2)     { FactoryGirl.create(:emp_delta,
                             employee: update_emp,
                             before: {"department_id"=>"1"},
                             after: {"department_id"=>"1"}) }

    it "should need a security access update" do
      expect(update_emp.needs_security_profile_update?).to eq(true)
    end

    it "should not need a security access update" do
      expect(no_update_emp.needs_security_profile_update?).to eq(false)
    end
  end
end
