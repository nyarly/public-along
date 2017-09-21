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
    let!(:regular_sp) { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
    let(:employee)    { FactoryGirl.create(:employee) }
    let!(:profile)    { FactoryGirl.create(:profile, employee: employee) }
    let(:ad)          { double(ActiveDirectoryService) }
    let(:mailer)      { double(ManagerMailer) }
    let(:os)          { double(OffboardingService) }
    let(:sas)         { double(SecAccessService) }

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
    end

    it "should create accounts and set as pending" do
      expect(SecAccessService).to receive(:new).and_return(sas)
      expect(sas).to receive(:apply_ad_permissions)
      expect(employee).to receive(:create_active_directory_account).and_return(ad)
      expect(Employee).to receive(:check_manager).and_return(true)
      expect(employee).to transition_from(:created).to(:pending).on_event(:hire)
      expect(employee).to have_state(:pending)
      expect(employee).to allow_event(:activate)
      expect(employee).to allow_transition_to(:active)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:terminated)
      expect(employee).not_to allow_transition_to(:inactive)
      expect(employee).not_to allow_event(:rehire)
      expect(employee).not_to allow_event(:start_leave)
      expect(employee).not_to allow_event(:end_leave)
      expect(employee).not_to allow_event(:terminate)
    end

    it "should start" do
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
    end

    it "should go on leave" do
      expect(employee).to receive(:deactivate_active_directory_account).and_return(ad)
      expect(employee).to transition_from(:active).to(:inactive).on_event(:start_leave)
      expect(employee).to have_state(:inactive)
      expect(employee).to allow_event(:activate)
      expect(employee).to allow_transition_to(:active)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:pending)
      expect(employee).not_to allow_transition_to(:terminated)
      expect(employee).not_to allow_event(:hire)
      expect(employee).not_to allow_event(:rehire)
      expect(employee).not_to allow_event(:terminate)
      expect(employee).not_to allow_event(:start_leave)
    end

    it "should return from leave" do
      expect(employee).to receive(:activate_active_directory_account).and_return(ad)
      expect(employee).to transition_from(:inactive).to(:active).on_event(:activate)
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
    end

    it "should be terminated" do
      expect(employee).to receive(:deactivate_active_directory_account).and_return(ad)
      expect(employee).to receive(:offboard).and_return(os)
      expect(employee).to transition_from(:active).to(:terminated).on_event(:terminate)
      expect(employee).to have_state(:terminated)
      expect(employee).to allow_event(:rehire)
      expect(employee).to allow_transition_to(:pending)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:inactive)
      expect(employee).not_to allow_transition_to(:active)
      expect(employee).not_to allow_event(:hire)
      expect(employee).not_to allow_event(:activate)
      expect(employee).not_to allow_event(:terminate)
      expect(employee).not_to allow_event(:start_leave)
    end

    it "should be rehired" do
      expect(employee).to transition_from(:terminated).to(:pending).on_event(:rehire)
      expect(employee).to have_state(:pending)
      expect(employee).to allow_event(:activate)
      expect(employee).to allow_transition_to(:active)
      expect(employee).not_to allow_transition_to(:terminated)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:inactive)
      expect(employee).not_to allow_event(:hire)
      expect(employee).not_to allow_event(:start_leave)
      expect(employee).not_to allow_event(:terminate)
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

    it "should scope the correct activation group" do
      activation_group = [
        FactoryGirl.create(:employee, :hire_date => Date.yesterday),
        FactoryGirl.create(:employee, :hire_date => Date.today),
        FactoryGirl.create(:employee, :hire_date => Date.tomorrow),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.yesterday),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.today),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.tomorrow)
      ]
      non_activation_group = [
        FactoryGirl.create(:employee, :hire_date => 1.week.ago),
        FactoryGirl.create(:employee, :hire_date => 2.days.ago),
        FactoryGirl.create(:employee, :hire_date => 2.days.from_now),
        FactoryGirl.create(:employee, :hire_date => 1.week.from_now),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 1.week.ago),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 2.days.ago),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 2.days.from_now),
        FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => 1.week.from_now)
      ]

      expect(Employee.activation_group).to match_array(activation_group)
      expect(Employee.activation_group).to_not include(non_activation_group)
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

    it "should scope the onboarding group" do
      onboarding_group = [
        FactoryGirl.create(:employee, :hire_date => Date.today),
        FactoryGirl.create(:employee, :hire_date => Date.today + 1.day),
        FactoryGirl.create(:employee, :hire_date => Date.today + 1.week),
        FactoryGirl.create(:employee, :hire_date => Date.today + 2.weeks)
      ]
      non_onboarding_group = [
        FactoryGirl.create(:employee, :hire_date => Date.today - 1.day),
        FactoryGirl.create(:employee, :hire_date => Date.today - 1.week),
        FactoryGirl.create(:employee, :hire_date => Date.today - 2.weeks)
      ]

      expect(Employee.onboarding_report_group).to match_array(onboarding_group)
      expect(Employee.onboarding_report_group).to_not include(non_onboarding_group)
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

      not_completed = FactoryGirl.create(:employee)

      expect(completed.onboarding_complete?).to eq(true)
      expect(not_completed.onboarding_complete?).to eq(false)
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
      emp_1 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2))
      prof_1 = FactoryGirl.create(:profile,
        employee: emp_1,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("San Francisco Headquarters"))
      emp_2 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2))
      prof_2 = FactoryGirl.create(:profile,
        employee: emp_2,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("London Office"))
      emp_3 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2))
      prof_3 = FactoryGirl.create(:profile,
        employee: emp_3,
        start_date: Date.new(2016, 7, 25),
        location: Location.find_by_name("Mumbai Office"))

      expect(emp_1.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_2.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_3.onboarding_due_date).to eq("Jul 11, 2016")
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
    let(:manager) { FactoryGirl.create(:regular_employee) }
    let(:mgr_profile) { FactoryGirl.create(:security_profile, name: "Basic Manager") }
    let(:app) { FactoryGirl.create(:application) }
    let(:access_level_1) {FactoryGirl.create(:access_level,
      application_id: app.id,
      ad_security_group: nil
    )}
    let(:access_level_2) {FactoryGirl.create(:access_level,
      application_id: app.id,
      ad_security_group: "distinguished name of AD sec group"
    )}
    let!(:spal_1) { FactoryGirl.create(:sec_prof_access_level,
      security_profile_id: mgr_profile.id,
      access_level_id: access_level_1.id
    )}
    let!(:spal_2) { FactoryGirl.create(:sec_prof_access_level,
      security_profile_id: mgr_profile.id,
      access_level_id: access_level_2.id
    )}
    let(:sas) { double(SecAccessService) }

    before :each do
      allow(SecAccessService).to receive(:new).and_return(sas)
    end

    it "should add 'Basic Manager' profile to worker if not present" do
      expect(sas).to receive(:apply_ad_permissions)

      expect{
        Employee.check_manager(manager.employee_id)
      }.to change{Employee.managers.include?(manager)}.from(false).to(true)
      expect(manager.emp_sec_profiles.last.security_profile_id).to eq(mgr_profile.id)
      expect(manager.active_security_profiles).to include(mgr_profile)
    end

    it "should apply AD security group if not nil" do
      expect(sas).to receive(:apply_ad_permissions)

      Employee.check_manager(manager.employee_id)
    end

    it "should do nothing if worker already has 'Basic Manager' profile" do
      emp_transaction = FactoryGirl.create(:emp_transaction,
        employee_id: manager.id)
      FactoryGirl.create(:emp_sec_profile,
        security_profile_id: mgr_profile.id,
        emp_transaction_id: emp_transaction.id)

      expect(sas).to_not receive(:apply_ad_permissions)

      expect{
        Employee.check_manager(manager.employee_id)
      }.to_not change{Employee.managers.include?(manager)}
      expect(Employee.managers.include?(manager)).to eq(true)
    end

    it "should not execute if nil is passed in" do
      expect(Employee).to_not receive(:managers)
      expect(SecurityProfile).to_not receive(:find)

      Employee.check_manager(nil)
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
      last_name: "Aaa",
      hire_date: 5.business_days.from_now)}
    let!(:profile) { FactoryGirl.create(:profile,
      profile_status: "pending",
      start_date: 5.business_days.from_now,
      employee: due_tomorrow_no_onboard)}

    let!(:due_tomorrow_no_onboard_au) { FactoryGirl.create(:pending_employee,
      last_name: "Bbb",
      hire_date: 10.business_days.from_now)}
    let!(:au_profile) { FactoryGirl.create(:profile,
      employee: due_tomorrow_no_onboard_au,
      profile_status: "pending",
      start_date: 10.business_days.from_now,
      location: Location.find_by_name("Melbourne Office"))}

    let!(:due_tomorrow_w_onboard) { FactoryGirl.create(:pending_employee,
      hire_date: 6.business_days.from_now)}
    let!(:due_tomorrow_no_onboard_profile) { FactoryGirl.create(:profile,
      profile_status: "pending",
      start_date: 6.business_days.from_now,
      employee: due_tomorrow_w_onboard)}
    let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
      kind: "Onboarding",
      employee: due_tomorrow_w_onboard) }
    let!(:onboard) { FactoryGirl.create(:onboarding_info,
      emp_transaction: emp_transaction)}

    let!(:due_later_no_onboard) { FactoryGirl.create(:pending_employee,
      hire_date: 14.days.from_now)}
    let!(:due_later_profile) { FactoryGirl.create(:profile,
      profile_status: "pending",
      start_date: 14.business_days.from_now,
      employee: due_later_no_onboard)}

    it "should return the right employees" do
      expect(Employee.onboarding_reminder_group).to eq([due_tomorrow_no_onboard, due_tomorrow_no_onboard_au])
    end
  end
end
