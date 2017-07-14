require 'rails_helper'

describe Employee, type: :model do
  let(:dept) { Department.find_by(name: "Customer Support") }

  let!(:location) { Location.find_by(:name => "London Office") }

  let!(:job_title) { FactoryGirl.create(:job_title)}

  let!(:reg_worker_type) { FactoryGirl.create(:worker_type, kind: "Regular")}
  let!(:temp_worker_type) { FactoryGirl.create(:worker_type, name: "Vendor", kind: "Temporary")}

  let!(:manager) { FactoryGirl.create(:employee,
    first_name: "Alex",
    last_name: "Trebek",
    department_id: dept.id,
    sam_account_name: "atrebek",
    employee_id: "at123",
    hire_date: 5.years.ago,
    ad_updated_at: 2.years.ago
  )}

  context "with a regular employee" do
    let(:employee) { FactoryGirl.build(:employee,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      sam_account_name: "bbarker",
      manager_id: manager.employee_id,
      location_id: location.id,
      job_title_id: job_title.id,
      worker_type_id: reg_worker_type.id
    )}

    it "should meet validations" do
      expect(employee).to be_valid

      expect(employee).to_not allow_value(nil).for(:first_name)
      expect(employee).to_not allow_value(nil).for(:last_name)
      expect(employee).to_not allow_value(nil).for(:hire_date)
      expect(employee).to_not allow_value(nil).for(:department_id)
      expect(employee).to_not allow_value(nil).for(:location_id)
      expect(employee).to_not allow_value(nil).for(:worker_type_id)
      expect(employee).to_not allow_value(nil).for(:job_title_id)
      expect(employee).to_not allow_value(nil).for(:employee_id)
      expect(employee).to     allow_value(nil).for(:email)
      expect(employee).to     validate_uniqueness_of(:employee_id).with_message(/Worker ID has already been taken/).case_insensitive
      expect(employee).to     validate_uniqueness_of(:email).case_insensitive
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
      mgr = FactoryGirl.create(:employee)
      emp = FactoryGirl.create(:employee)

      sp = FactoryGirl.create(:security_profile, name: "Basic Manager")
      et = FactoryGirl.create(:emp_transaction, employee_id: mgr.id)
      esp = FactoryGirl.create(:emp_sec_profile, security_profile_id: sp.id, emp_transaction_id: et.id)

      expect(Employee.managers).to include(mgr)
      expect(Employee.managers).to_not include(emp)
    end

    it "should scope the create group" do
      create_group = FactoryGirl.create_list(:employee, 10, :department_id => dept.id)
      existing_group = FactoryGirl.create_list(:employee, 10, :existing)

      expect(Employee.create_group).to match_array(create_group)
      expect(Employee.create_group).to_not include(existing_group)
    end

    it "should scope the update group" do
      create_group = FactoryGirl.create_list(:employee, 10, :department_id => dept.id)
      existing_group = FactoryGirl.create_list(:employee, 10, :existing)
      update1 = FactoryGirl.create(:employee,
        :updated_at => Time.now,
        :ad_updated_at => Date.yesterday)

      expect(Employee.update_group).to include(update1)
      expect(Employee.update_group).to_not include(create_group)
      expect(Employee.update_group).to_not include(existing_group)
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
      reg_worker_type = FactoryGirl.create(:worker_type, kind: "Regular")
      temp_worker_type = FactoryGirl.create(:worker_type, kind: "Temporary")
      reg_emp = FactoryGirl.create(:employee, worker_type_id: reg_worker_type.id)
      contingent_emp = FactoryGirl.create(:employee, worker_type_id: temp_worker_type.id)

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
      emp_trans_1 = FactoryGirl.create(:emp_transaction, kind: "Onboarding", employee_id: completed.id)
      onboarding_info = FactoryGirl.create(:onboarding_info, emp_transaction_id: emp_trans_1.id)

      not_completed = FactoryGirl.create(:employee)


      expect(completed.onboarding_complete?).to eq(true)
      expect(not_completed.onboarding_complete?).to eq(false)
    end

    it "should check offboarding is complete" do
      completed = FactoryGirl.create(:employee)
      emp_trans_1 = FactoryGirl.create(:emp_transaction, kind: "Offboarding", employee_id: completed.id)
      offboarding_info = FactoryGirl.create(:offboarding_info, emp_transaction_id: emp_trans_1.id)

      not_completed = FactoryGirl.create(:employee)


      expect(completed.offboarding_complete?).to eq(true)
      expect(not_completed.offboarding_complete?).to eq(false)
    end

    it "should find active/revoked security profiles" do
      emp = FactoryGirl.create(:employee)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      user = FactoryGirl.create(:user)
      emp_transaction = FactoryGirl.create(:emp_transaction,
        employee_id: emp.id,
        kind: "Onboarding")
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
      dept = FactoryGirl.create(:department)
      emp = FactoryGirl.create(:employee, department_id: dept.id)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      emp_trans = FactoryGirl.create(:emp_transaction, employee_id: emp.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof_1.id,
        revoking_transaction_id: nil)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans.id,
        security_profile_id: sec_prof_2.id,
        revoking_transaction_id: nil)
      dept_sec_prof_1 = FactoryGirl.create(:dept_sec_prof,
        department_id: dept.id,
        security_profile_id: sec_prof_1.id)

      expect(emp.security_profiles_to_revoke).to include(sec_prof_2)
      expect(emp.security_profiles_to_revoke).to_not include(sec_prof_1)
    end

    it "should calculate an onboarding due date according to location" do
      emp_1 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2),
        location: Location.find_by_name("San Francisco Headquarters")
      )

      emp_2 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2),
        location: Location.find_by_name("London Office")
      )

      emp_3 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2),
        location: Location.find_by_name("Mumbai Office")
      )

      expect(emp_1.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_2.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_3.onboarding_due_date).to eq("Jul 11, 2016")
    end

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

    it "should set the nearest time zone" do
      expect(employee.nearest_time_zone).to eq("Europe/London")
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
          workdayUsername: employee.workday_username,
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
    let(:employee) { FactoryGirl.build(:employee,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      job_title_id: job_title.id,
      manager_id: "at123",
      sam_account_name: "mrbobbarker",
      worker_type_id: reg_worker_type.id
    )}

    it "should generate an email using the sAMAccountName" do
      expect(employee.generated_email).to eq("mrbobbarker@opentable.com")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          dn: "cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: "mrbobbarker",
          displayName: employee.cn,
          userPrincipalName: employee.generated_upn,
          manager: manager.dn,
          mail: "mrbobbarker@opentable.com",
          unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
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
    let(:employee) { FactoryGirl.build(:employee, :contingent,
      first_name: "Bob",
      last_name: "Barker",
      employee_type: "Vendor",
      department_id: dept.id,
      location_id: location.id,
      job_title_id: job_title.id,
      manager_id: "at123",
      sam_account_name: "senorbob",
      contract_end_date: 1.month.from_now,
      worker_type_id: temp_worker_type.id
    )}

    it "should not generate an email when sAMAccountName is set" do
      expect(employee.generated_email).to be_nil
    end

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
          workdayUsername: employee.workday_username,
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

  context "with a terminated worker" do
    let(:employee) { FactoryGirl.build(:employee,
      department_id: dept.id,
      location_id: location.id,
      termination_date: 2.days.from_now
    )}

    it "should set the correct account expiry" do
      date = employee.termination_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
    end
  end

  context "with a contingent worker that has been terminated" do
    let(:employee) { FactoryGirl.build(:employee, :contingent,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      location_id: location.id,
      job_title_id: job_title.id,
      manager_id: "at123",
      contract_end_date: 1.month.from_now,
      termination_date: 1.day.from_now,
      worker_type_id: temp_worker_type.id
    )}

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
          workdayUsername: employee.workday_username,
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
    let(:employee) { FactoryGirl.build(:employee, :remote,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      job_title_id: job_title.id,
      manager_id: "at123",
      home_address_1: "123 Fake St.",
      home_city: "Beverly Hills",
      home_state: "CA",
      home_zip: "90210",
      worker_type_id: reg_worker_type.id
    )}

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
          workdayUsername: employee.workday_username,
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
    let(:employee) { FactoryGirl.build(:employee, :remote,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      job_title_id: job_title.id,
      manager_id: "at123",
      home_address_1: "123 Fake St.",
      home_address_2: "Apt 3G",
      home_city: "Beverly Hills",
      home_state: "CA",
      home_zip: "90210",
      worker_type_id: reg_worker_type.id
    )}

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
          workdayUsername: employee.workday_username,
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

  context "when it does not find a location and department ou match" do
    let!(:location) { Location.find_by(:name => "London Office") }
    let!(:department) { Department.find_by(name: "Risk Management") }
    let!(:employee) { FactoryGirl.build(:employee,
      first_name: "Charlie",
      last_name: "Brown",
      location_id: location.id,
      department_id: department.id
    )}

    it "should assign the user to the provisional ou" do
      expect(employee.ou).to eq("ou=Provisional,ou=Users,")
    end
  end

  describe "#check_manager" do
    let(:manager) { FactoryGirl.create(:employee) }
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
      expect(Employee.email_options(employee.id)).to eq(Employee::EMAIL_OPTIONS)
    end

    it "should return EMAIL_OPTIONS without offboarding option" do
      employee = FactoryGirl.create(:employee, termination_date: nil)
      expect(Employee.email_options(employee.id)).to_not include("Offboarding")
    end
  end
end
