require 'rails_helper'

describe Employee, type: :model do
  let(:dept) { Department.find_by(name: "Customer Support") }

  let!(:location) { Location.find_by(:name => "London") }

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
      location_id: location.id
    )}

    it "should meet validations" do
      expect(employee).to be_valid

      expect(employee).to_not allow_value(nil).for(:first_name)
      expect(employee).to_not allow_value(nil).for(:last_name)
      expect(employee).to_not allow_value(nil).for(:department_id)
      expect(employee).to_not allow_value(nil).for(:location_id)
      expect(employee).to     allow_value(nil).for(:email)
      expect(employee).to     validate_uniqueness_of(:employee_id).with_message(/Worker ID has already been taken/).case_insensitive
      expect(employee).to     validate_uniqueness_of(:email).case_insensitive
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
        FactoryGirl.create(:employee, :termination_date => Date.today + 1.week)
      ]

      sec_prof = FactoryGirl.create(:security_profile)

      offboarding_group.each do |emp|
        emp_trans = FactoryGirl.create(:emp_transaction, :kind => "Offboarding")
        emp_sec_prof = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans.id, employee_id: emp.id, security_profile_id: sec_prof.id)
      end

      non_offboarding_group.each do |emp|
        emp_trans = FactoryGirl.create(:emp_transaction, :kind => "Offboarding")
        emp_sec_prof = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans.id, employee_id: emp.id, security_profile_id: sec_prof.id)
      end

      incomplete_offboarder = FactoryGirl.create(:employee, :first_name => "INCOMPLETE @#$%^&*%$#$%^", :termination_date => 2.weeks.ago)
      late_offboarder = FactoryGirl.create(:employee, :first_name => "LATE @#$%^&*%$#$%^", :termination_date => 2.weeks.ago)

      emp_trans_0 = FactoryGirl.create(:emp_transaction, :kind => "Onboarding")
      emp_sec_prof_0 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_0.id, employee_id: incomplete_offboarder.id, security_profile_id: sec_prof.id)

      emp_trans_1 = FactoryGirl.create(:emp_transaction, :kind => "Offboarding", :created_at => 1.day.ago)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: late_offboarder.id, security_profile_id: sec_prof.id)

      expect(Employee.offboard_group).to match_array(offboarding_group)
      expect(Employee.offboarding_report_group).to_not include(non_offboarding_group)
      expect(Employee.late_offboard_group).to include(late_offboarder)
      expect(Employee.incomplete_offboard_group).to include(incomplete_offboarder)
      expect(Employee.offboarding_report_group).to match_array(offboarding_group + [late_offboarder, incomplete_offboarder])
    end

    it "should check onboarding is complete" do
      sec_prof = FactoryGirl.create(:security_profile)

      completed = FactoryGirl.create(:employee)
      emp_trans_1 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: completed.id, security_profile_id: sec_prof.id)

      not_completed = FactoryGirl.create(:employee)
      emp_trans_2 = FactoryGirl.create(:emp_transaction, kind: "Security Access")
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_2.id, employee_id: not_completed.id, security_profile_id: sec_prof.id)


      expect(completed.onboarding_complete?).to eq(true)
      expect(not_completed.onboarding_complete?).to eq(false)
    end

    it "should find active/revoked security profiles" do
      emp = FactoryGirl.create(:employee)
      sec_prof_1 = FactoryGirl.create(:security_profile)
      sec_prof_2 = FactoryGirl.create(:security_profile)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, employee_id: emp.id, security_profile_id: sec_prof_1.id, revoking_transaction_id: 1)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile, employee_id: emp.id, security_profile_id: sec_prof_2.id, revoking_transaction_id: nil)

      expect(emp.active_security_profiles).to include(sec_prof_2)
      expect(emp.revoked_security_profiles).to include(sec_prof_1)
    end

    it "should calculate an onboarding due date according to location" do
      emp_1 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2),
        location: Location.find_by_name("San Francisco")
      )

      emp_2 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2),
        location: Location.find_by_name("London")
      )

      emp_3 = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 25, 2),
        location: Location.find_by_name("Mumbai")
      )

      expect(emp_1.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_2.onboarding_due_date).to eq("Jul 18, 2016")
      expect(emp_3.onboarding_due_date).to eq("Jul 11, 2016")
    end

    it "should create a cn" do
      expect(employee.cn).to eq("Bob Barker")
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
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          thumbnailPhoto: Base64.decode64(employee.image_code)
        }
      )
    end
  end

  context "regular worker that has been assigned a sAMAccountName" do
    let(:employee) { FactoryGirl.build(:employee,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      manager_id: "at123",
      sam_account_name: "mrbobbarker"
    )}

    it "should generate an email using the sAMAccountName" do
      expect(employee.generated_email).to eq("mrbobbarker@opentable.com")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: "mrbobbarker",
          manager: manager.dn,
          mail: "mrbobbarker@opentable.com",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          thumbnailPhoto: Base64.decode64(employee.image_code)
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
      manager_id: "at123",
      sam_account_name: "senorbob",
      contract_end_date: 1.month.from_now
    )}

    it "should not generate an email when sAMAccountName is set" do
      expect(employee.generated_email).to be_nil
    end

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(1.month.from_now))
    end

    it "should set the correct address" do
      expect(employee.generated_address).to be_nil
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          thumbnailPhoto: Base64.decode64(employee.image_code)
        }
      )
    end
  end

  context "with a terminated worker" do
    let(:employee) { FactoryGirl.build(:employee,
      department_id: dept.id,
      termination_date: 2.days.from_now
    )}

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(2.days.from_now))
    end
  end

  context "with a contingent worker that has been terminated" do
    let(:employee) { FactoryGirl.build(:employee, :contingent,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      manager_id: "at123",
      contract_end_date: 1.month.from_now,
      termination_date: 1.day.from_now
    )}

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(1.day.from_now))
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: employee.generated_address,
          l: employee.home_city,
          st: employee.home_state,
          postalCode: employee.home_zip,
          thumbnailPhoto: Base64.decode64(employee.image_code)
        }
      )
    end
  end

  context "with a remote worker and one address line" do
    let(:employee) { FactoryGirl.build(:employee, :remote,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      manager_id: "at123",
      home_address_1: "123 Fake St.",
      home_city: "Beverly Hills",
      home_state: "CA",
      home_state: "CA",
      home_zip: "90210"
    )}

    it "should set the correct address" do
      expect(employee.generated_address).to eq("123 Fake St.")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: "123 Fake St.",
          l: "Beverly Hills",
          st: "CA",
          postalCode: "90210",
          thumbnailPhoto: Base64.decode64(employee.image_code)
        }
      )
    end
  end

  context "with a remote worker and two address lines" do
    let(:employee) { FactoryGirl.build(:employee, :remote,
      first_name: "Bob",
      last_name: "Barker",
      department_id: dept.id,
      manager_id: "at123",
      home_address_1: "123 Fake St.",
      home_address_2: "Apt 3G",
      home_city: "Beverly Hills",
      home_state: "CA",
      home_zip: "90210"
    )}

    it "should set the correct address" do
      expect(employee.generated_address).to eq("123 Fake St., Apt 3G")
    end

    it "should create attr hash" do
      expect(employee.ad_attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: employee.sam_account_name,
          manager: manager.dn,
          mail: employee.email,
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.location.country,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location.name,
          department: employee.department.name,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: "123 Fake St., Apt 3G",
          l: "Beverly Hills",
          st: "CA",
          postalCode: "90210",
          thumbnailPhoto: Base64.decode64(employee.image_code)
        }
      )
    end
  end
end
