require 'rails_helper'

describe Employee, type: :model do
  let(:employee) { FactoryGirl.build(:employee,
    first_name: "Bob",
    last_name: "Barker"
  ) }

  it "should meet validations" do
    expect(employee).to be_valid

    expect(employee).to_not allow_value(nil).for(:first_name)
    expect(employee).to_not allow_value(nil).for(:last_name)
  end

  it "should create a cn" do
    expect(employee.cn).to eq("Bob Barker")
  end

  it "should create a dn" do
    expect(employee.dn).to eq("cn=Bob Barker,cn=Users,dc=ottest,dc=opentable,dc=com")
  end

  it "should create a sAMAccountName" do
    expect(employee.sAMAccountName).to eq("bbarker")
  end

  it "should create attr hash" do
    expect(employee.attrs).to eq(
      {
        cn: "Bob Barker",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Bob",
        sn: "Barker",
        sAMAccountName: "bbarker",
        mail: "bbarker@opentable.com",
        unicodePwd: "\"Password!12345\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
      }
    )
  end

  xit "should create an ldap connection" do
  end

  xit "should create an ad user" do
  end

  xit "should modify the user to be a normal user" do
  end
end
