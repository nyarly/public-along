require 'rails_helper'
require 'aasm/rspec'

describe Employee, type: :model do

  let!(:manager) { FactoryGirl.create(:employee,
                   first_name: "Alex",
                   last_name: "Trebek",
                   sam_account_name: "atrebek",
                   hire_date: 5.years.ago,
                   ad_updated_at: 2.years.ago) }

  describe "state machine" do
    let(:pending_onboard) { FactoryGirl.create(:employee,
                            status: "pending",
                            request_status: "waiting") }
    let!(:pend_onboard_p) { FactoryGirl.create(:profile,
                            employee: pending_onboard,
                            profile_status: "pending") }
    let(:pending_start)   { FactoryGirl.create(:employee,
                            status: "pending",
                            request_status: "completed") }
    let!(:pend_start_p)   { FactoryGirl.create(:profile,
                            employee: pending_start,
                            profile_status: "pending") }
    let!(:employee)       { FactoryGirl.create(:employee, :with_profile,
                            manager: manager) }
    let(:active_employee) { FactoryGirl.create(:active_employee) }
    let(:leave_employee)  { FactoryGirl.create(:leave_employee) }
    let(:termed_employee) { FactoryGirl.create(:terminated_employee) }
    let!(:new_profile)    { FactoryGirl.create(:profile,
                            employee: termed_employee) }
    let(:pending_rehire)  { FactoryGirl.create(:employee,
                            status: "pending") }
    let!(:pend_reh_p_1)   { FactoryGirl.create(:profile,
                            employee: pending_rehire,
                            profile_status: "terminated") }
    let!(:pend_reh_p_2)   { FactoryGirl.create(:profile,
                            employee: pending_rehire,
                            profile_status: "pending") }
    let(:ad)              { double(ActiveDirectoryService) }
    let(:os)              { double(OffboardingService) }
    let(:onboard_service) { double(EmployeeService::Onboard) }

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
    end

    it "employee.hire! should create accounts and set as pending" do
      employee.hire!

      expect(employee).to have_state(:pending)
      expect(employee).not_to allow_transition_to(:created)
      expect(employee).not_to allow_transition_to(:terminated)
      expect(employee).not_to allow_transition_to(:inactive)
      expect(employee).not_to allow_event(:rehire)
      expect(employee).not_to allow_event(:start_leave)
      expect(employee).not_to allow_event(:end_leave)
      expect(employee).not_to allow_event(:terminate)

      expect(employee.status).to eq("pending")
      expect(employee.current_profile.profile_status).to eq("pending")
    end

    it "employee.activate! should make employee active" do
      expect(ActiveDirectoryService).to receive(:new).and_return(ad)
      expect(ad).to receive(:activate).with([pending_start])

      pending_start.activate!

      expect(pending_start).to have_state(:active)
      expect(pending_start).to allow_event(:start_leave)
      expect(pending_start).to allow_event(:terminate)
      expect(pending_start).to allow_transition_to(:inactive)
      expect(pending_start).to allow_transition_to(:terminated)
      expect(pending_start).not_to allow_transition_to(:created)
      expect(pending_start).not_to allow_transition_to(:pending)
      expect(pending_start).to have_state(:none).on(:request_status)

      expect(pending_start.status).to eq("active")
      expect(pending_start.request_status).to eq("none")
      expect(pending_start.current_profile.profile_status).to eq("active")
    end

    it "employee.activate! should make rehire active" do
      expect(ActiveDirectoryService).to receive(:new).and_return(ad)
      expect(ad).to receive(:activate).with([pending_rehire])

      pending_rehire.activate!

      expect(pending_rehire).to have_state(:active)
      expect(pending_rehire).to allow_event(:start_leave)
      expect(pending_rehire).to allow_event(:terminate)
      expect(pending_rehire).to allow_transition_to(:inactive)
      expect(pending_rehire).to allow_transition_to(:terminated)
      expect(pending_rehire).not_to allow_transition_to(:created)
      expect(pending_rehire).not_to allow_transition_to(:pending)
      expect(pending_rehire).to have_state(:none).on(:request_status)

      expect(pending_rehire.status).to eq("active")
      expect(pending_rehire.request_status).to eq("none")
      expect(pending_rehire.current_profile).to eq(pend_reh_p_2)
      expect(pend_reh_p_2.reload.profile_status).to eq("active")
      expect(pend_reh_p_1.reload.profile_status).to eq("terminated")
    end

    it "should not activate employee if onboarding form is not complete" do
      expect(ActiveDirectoryService).not_to receive(:new)

      pending_onboard.activate!

      expect(pending_onboard).to have_state(:pending)
      expect(pending_onboard).not_to allow_event(:terminate)
      expect(pending_onboard).not_to allow_transition_to(:created)
      expect(pending_onboard).not_to allow_transition_to(:active)
      expect(pending_onboard).not_to allow_event(:hire)
      expect(pending_onboard).not_to allow_event(:rehire)
      expect(pending_onboard).not_to allow_event(:activate)
      expect(pending_onboard).to have_state(:waiting).on(:request_status)

      expect(pending_onboard.status).to eq("pending")
      expect(pending_onboard.request_status).to eq("waiting")
      expect(pending_onboard.current_profile.profile_status).to eq("pending")
    end

    it "employee.start_leave! should put employee on leave" do
      expect(ActiveDirectoryService).to receive(:new).and_return(ad)
      expect(ad).to receive(:deactivate).with([active_employee])

      active_employee.start_leave!

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

      expect(active_employee.status).to eq("inactive")
      expect(active_employee.current_profile.profile_status).to eq("leave")
      expect(active_employee.request_status).to eq("none")
    end

    it "employee.activate! should return employee from leave" do
      expect(ActiveDirectoryService).to receive(:new).and_return(ad)
      expect(ad).to receive(:activate).with([leave_employee])

      leave_employee.activate!

      expect(leave_employee).to have_state(:active)
      expect(leave_employee).to allow_event(:start_leave)
      expect(leave_employee).to allow_event(:terminate)
      expect(leave_employee).to allow_transition_to(:inactive)
      expect(leave_employee).to allow_transition_to(:terminated)
      expect(leave_employee).not_to allow_transition_to(:created)
      expect(leave_employee).not_to allow_transition_to(:pending)
      expect(leave_employee).to have_state(:none).on(:request_status)

      expect(leave_employee.status).to eq("active")
      expect(leave_employee.request_status).to eq("none")
      expect(leave_employee.current_profile.profile_status).to eq("active")
    end

    it "employee.terminate! should terminate employee" do
      expect(active_employee).to receive(:deactivate_active_directory_account).and_return(ad)
      expect(active_employee).to receive(:offboard).and_return(os)

      active_employee.terminate!

      expect(active_employee).to have_state(:terminated)
      expect(active_employee).to allow_transition_to(:pending)
      expect(active_employee).not_to allow_transition_to(:created)
      expect(active_employee).not_to allow_transition_to(:inactive)
      expect(active_employee).not_to allow_transition_to(:active)
      expect(active_employee).not_to allow_event(:activate)
      expect(active_employee).not_to allow_event(:terminate)
      expect(active_employee).not_to allow_event(:start_leave)
      expect(active_employee).to have_state(:none).on(:request_status)

      expect(active_employee.status).to eq("terminated")
      expect(active_employee.current_profile.profile_status).to eq("terminated")
    end
  end

  context "with a regular employee" do
    let(:employee) { FactoryGirl.create(:employee,
      first_name: "Bob",
      last_name: "Barker",
      sam_account_name: "bbarker",
      hire_date: 1.year.ago,
      ad_updated_at: 1.hour.ago) }

    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou, employee: employee) }

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

      expect(emp_1.onboarding_due_date).to eq(DateTime.new(2016, 7, 18, 9, 0, 0, "+00:00"))
      expect(emp_2.onboarding_due_date).to eq(DateTime.new(2016, 7, 18, 9, 0, 0, "+00:00"))
      expect(emp_3.onboarding_due_date).to eq(DateTime.new(2016, 7, 11, 9, 0, 0, "+00:00"))
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

      expect(employee.onboarding_due_date).to eq(DateTime.new(2017, 9, 18, 9, 0, 0, "+00:00"))
      expect(employee.start_date).to eq(DateTime.new(2017, 9, 25, 0, 0, 0, "+00:00"))
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
    let!(:due_tomorrow_no_onboard) { FactoryGirl.create(:pending_employee,
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

    let!(:due_tomorrow_w_onboard) { FactoryGirl.create(:employee,
      last_name: "CCC",
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

    let!(:due_later_no_onboard) { FactoryGirl.create(:employee,
      last_name: "DDD",
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
    let(:employee) { FactoryGirl.create(:active_employee, :with_manager,
                     first_name: "Bob",
                     last_name: "Barker") }
    let!(:profile) { FactoryGirl.create(:active_profile, :with_valid_ou,
                     employee: employee) }

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
      expect(employee.address).to be_nil
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
          manager: employee.manager.dn,
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
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "regular worker that has been assigned a sAMAccountName" do
    let(:employee) { FactoryGirl.create(:employee, :with_manager,
                     first_name: "Mary",
                     last_name: "Sue",
                     sam_account_name: "msue",
                     email: nil) }
    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                     employee: employee) }

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
          manager: employee.manager.dn,
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
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "with a contingent worker" do
    let(:employee) { FactoryGirl.create(:employee, :with_manager,
                     first_name: "Sally",
                     last_name: "Field",
                     sam_account_name: "sfield",
                     contract_end_date: 1.month.from_now) }

    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
                     employee: employee) }

    it "should set the correct account expiry" do
      date = employee.contract_end_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
    end

    it "should set the correct address" do
      expect(employee.address).to be_nil
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
          manager: employee.manager.dn,
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
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context "with a contingent worker that has been terminated" do
    let(:cont_wt)  { FactoryGirl.create(:worker_type, :contractor) }
    let(:employee) { FactoryGirl.create(:terminated_employee, :with_manager,
                     first_name: "Bob",
                     last_name: "Barker",
                     contract_end_date: 1.month.from_now,
                     termination_date: 1.day.from_now) }

    let!(:profile) { FactoryGirl.create(:terminated_profile, :with_valid_ou,
                     worker_type: cont_wt,
                     employee: employee) }

    it "should set the correct account expiry" do
      date = employee.termination_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          dn: "cn=Bob Barker,ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: employee.manager.dn,
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
          streetAddress: nil,
          l: nil,
          st: nil,
          postalCode: nil,
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end


  context 'with a remote worker and one address line' do
    let(:employee) { FactoryGirl.create(:employee, :with_manager,
                     first_name: 'Bob',
                     last_name: 'Barker') }
    let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou, :remote,
                     employee: employee) }
    let!(:address) { FactoryGirl.create(:address,
                     line_1: '123 Fake St.',
                     line_2: nil,
                     city: 'Beverly Hills',
                     state_territory: 'CA',
                     postal_code: '90210',
                     addressable_type: 'Employee',
                     addressable_id: employee.id) }

    it 'should set the correct address' do
      expect(employee.address.complete_street).to eq('123 Fake St.')
    end

    it 'should create attr hash' do
      expect(employee.ad_attrs).to eq(
        {
          cn: 'Bob Barker',
          dn: 'cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Bob',
          sn: 'Barker',
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: employee.manager.dn,
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
          streetAddress: '123 Fake St.',
          l: 'Beverly Hills',
          st: 'CA',
          postalCode: '90210',
          # thumbnailPhoto: Base64.decode64(employee.image_code)
          # TODO comment back in when we bring back thumbnail photo
        }
      )
    end
  end

  context 'with a remote worker and two address lines' do
    let(:remote_loc)  { FactoryGirl.create(:location, :remote) }
    let(:employee)    { FactoryGirl.create(:employee, :with_manager,
                        first_name: 'Bob',
                        last_name: 'Barker') }
    let!(:profile)    { FactoryGirl.create(:profile,
                        employee: employee,
                        location: remote_loc,
                        department: Department.find_by_name('Customer Support')) }
    let!(:address) { FactoryGirl.create(:address,
                     line_1: '123 Fake St.',
                     line_2: 'Apt 3G',
                     city: 'Beverly Hills',
                     state_territory: 'CA',
                     postal_code: '90210',
                     addressable_type: 'Employee',
                     addressable_id: employee.id) }

    it 'should set the correct address' do
      expect(employee.address.complete_street).to eq('123 Fake St., Apt 3G')
    end

    it 'should create attr hash' do
      expect(employee.ad_attrs).to eq(
        {
          cn: 'Bob Barker',
          dn: 'cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com',
          objectclass: ['top', 'person', 'organizationalPerson', 'user'],
          givenName: 'Bob',
          sn: 'Barker',
          sAMAccountName: employee.sam_account_name,
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: employee.manager.dn,
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
          streetAddress: '123 Fake St., Apt 3G',
          l: 'Beverly Hills',
          st: 'CA',
          postalCode: '90210',
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
                     employee: employee) }

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

  context "#last_changed_at" do
    let(:yesterday)                 { 1.day.ago }
    let(:two_days_ago)              { 2.days.ago }
    let(:last_week)                 { 1.week.ago }
    let(:last_changed_at_onboard)   { FactoryGirl.create(:employee,
                                      created_at: last_week) }
    let(:onboard)                   { FactoryGirl.create(:emp_transaction,
                                      employee: last_changed_at_onboard,
                                      created_at: two_days_ago) }
    let!(:onboard_info)             { FactoryGirl.create(:onboarding_info,
                                      emp_transaction: onboard,
                                      created_at: two_days_ago) }
    let(:last_changed_at_emp_delta) { FactoryGirl.create(:employee,
                                      created_at: last_week) }
    let(:onboard_2)                 { FactoryGirl.create(:emp_transaction,
                                      employee: last_changed_at_emp_delta,
                                      created_at: two_days_ago) }
    let!(:onboard_info_2)           { FactoryGirl.create(:onboarding_info,
                                      emp_transaction: onboard_2,
                                      created_at: two_days_ago) }
    let!(:emp_delta)                { FactoryGirl.create(:emp_delta,
                                      employee: last_changed_at_emp_delta,
                                      before: {"thing"=>"thing"},
                                      after: {"thing"=>"thing"},
                                      created_at: yesterday) }
    let(:last_changed_at_offboard)  { FactoryGirl.create(:employee) }
    let(:offboard)                  { FactoryGirl.create(:emp_transaction,
                                      employee: last_changed_at_offboard,
                                      created_at: two_days_ago) }
    let!(:offboard_info)            { FactoryGirl.create(:offboarding_info,
                                      emp_transaction: offboard,
                                      created_at: two_days_ago) }
    let(:last_changed_at_create)    { FactoryGirl.create(:employee,
                                      created_at: last_week) }

    it "should get the right date last changed" do
      expect(last_changed_at_onboard.last_changed_at).to eq(two_days_ago)
      expect(last_changed_at_emp_delta.last_changed_at).to eq(yesterday)
      expect(last_changed_at_offboard.last_changed_at).to eq(two_days_ago)
      expect(last_changed_at_create.last_changed_at).to eq(last_week)
    end
  end
end
