require 'rails_helper'

describe Employee, type: :model do
  context "with a regular employee" do
    let(:employee) { FactoryGirl.build(:employee,
      first_name: "Bob",
      last_name: "Barker",
      cost_center: "OT Customer Support",
      country: "UK"
    )}

    it "should meet validations" do
      expect(employee).to be_valid

      expect(employee).to_not allow_value(nil).for(:first_name)
      expect(employee).to_not allow_value(nil).for(:last_name)
    end

    it "should create a cn" do
      expect(employee.cn).to eq("Bob Barker")
    end

    it "should find the correct ou" do
      expect(employee.ou).to eq("ou=Operations,ou=EU,")
    end

    it "should create a dn" do
      expect(employee.dn).to eq("cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
    end

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to be_nil
    end

    it "should set the correct address" do
      expect(employee.generated_address).to be_nil
    end

    it "should create attr hash" do
      expect(employee.attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.country,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location,
          department: employee.cost_center,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          thumbnailPhoto: employee.image_code
        }
      )
    end
  end

  context "regular worker that has been assigned a sAMAccountName" do
    let(:employee) { FactoryGirl.build(:employee,
      first_name: "Bob",
      last_name: "Barker"
    )}

    it "should generate an email using the sAMAccountName" do
      employee.sAMAccountName = "mrbobbarker"

      expect(employee.generated_email).to eq("mrbobbarker@opentable.com")
    end

    it "should create attr hash" do
      employee.sAMAccountName = "mrbobbarker"

      expect(employee.attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          sAMAccountName: "mrbobbarker",
          mail: "mrbobbarker@opentable.com",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.country,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location,
          department: employee.cost_center,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          thumbnailPhoto: employee.image_code
        }
      )
    end
  end

  context "with a contingent worker" do
    let(:employee) { FactoryGirl.build(:employee, :contingent,
      first_name: "Bob",
      last_name: "Barker",
      contract_end_date: 1.month.from_now
    )}

    it "should not generate an email when sAMAccountName is set" do
      employee.sAMAccountName = "senorbob"
      expect(employee.generated_email).to be_nil
    end

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(1.month.from_now))
    end

    it "should set the correct address" do
      expect(employee.generated_address).to be_nil
    end

    it "should create attr hash" do
      expect(employee.attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.country,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location,
          department: employee.cost_center,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          thumbnailPhoto: employee.image_code
        }
      )
    end
  end

  context "with a terminated worker" do
    let(:employee) { FactoryGirl.build(:employee,
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
      contract_end_date: 1.month.from_now,
      termination_date: 1.day.from_now
    )}

    it "should set the correct account expiry" do
      expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(1.day.from_now))
    end

    it "should create attr hash" do
      expect(employee.attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.country,
          accountExpires: employee.generated_account_expires,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location,
          department: employee.cost_center,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          thumbnailPhoto: employee.image_code
        }
      )
    end
  end

  context "with a remote worker and one address line" do
    let(:employee) { FactoryGirl.build(:employee, :remote,
      first_name: "Bob",
      last_name: "Barker",
      home_address_1: "123 Fake St.",
      home_city: "Beverly Hills",
      home_state: "CA",
      home_zip: "90210"
    )}

    it "should set the correct address" do
      expect(employee.generated_address).to eq("123 Fake St.")
    end

    it "should create attr hash" do
      expect(employee.attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.country,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location,
          department: employee.cost_center,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: "123 Fake St.",
          l: "Beverly Hills",
          st: "CA",
          postalCode: "90210",
          thumbnailPhoto: employee.image_code
        }
      )
    end
  end

  context "with a remote worker and two address lines" do
    let(:employee) { FactoryGirl.build(:employee, :remote,
      first_name: "Bob",
      last_name: "Barker",
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
      expect(employee.attrs).to eq(
        {
          cn: "Bob Barker",
          objectclass: ["top", "person", "organizationalPerson", "user"],
          givenName: "Bob",
          sn: "Barker",
          unicodePwd: "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
          workdayUsername: employee.workday_username,
          co: employee.country,
          title: employee.business_title,
          description: employee.business_title,
          employeeType: employee.employee_type,
          physicalDeliveryOfficeName: employee.location,
          department: employee.cost_center,
          employeeID: employee.employee_id,
          mobile: employee.personal_mobile_phone,
          telephoneNumber: employee.office_phone,
          streetAddress: "123 Fake St., Apt 3G",
          l: "Beverly Hills",
          st: "CA",
          postalCode: "90210",
          thumbnailPhoto: employee.image_code
        }
      )
    end
  end
end
