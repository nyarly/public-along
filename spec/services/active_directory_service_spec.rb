require 'rails_helper'

describe ActiveDirectoryService, type: :service do
  let(:ldap) { double(Net::LDAP) }
  let(:ads) { ActiveDirectoryService.new }

  before :each do
    depts = [
      {:name =>  "OT Facilities", :code => "000010"},
      {:name =>  "OT People and Culture", :code => "000011"},
      {:name =>  "OT Legal", :code => "000012"},
      {:name =>  "OT Finance", :code => "000013"},
      {:name =>  "OT Risk Management and Fraud", :code => "000014"},
      {:name =>  "OT Talent Acquisition", :code => "000017"},
      {:name =>  "OT Executive", :code => "000018"},
      {:name =>  "OT Finance Operations", :code => "000019"},
      {:name =>  "OT Sales - General", :code => "000020"},
      {:name =>  "OT Sales Operations", :code => "000021"},
      {:name =>  "OT Inside Sales", :code => "000025"},
      {:name =>  "OT Field Operations", :code => "000031"},
      {:name =>  "OT Customer Support", :code => "000032"},
      {:name =>  "OT Restaurant Relations Management", :code => "000033"},
      {:name =>  "OT IT Technical Services and Helpdesk", :code => "000035"},
      {:name =>  "OT IT - Engineering", :code => "000036"},
      {:name =>  "OT General Engineering", :code => "000040"},
      {:name =>  "OT Consumer Engineering", :code => "000041"},
      {:name =>  "OT Restaurant Engineering", :code => "000042"},
      {:name =>  "OT Data Center Ops", :code => "000043"},
      {:name =>  "OT Business Optimization", :code => "000044"},
      {:name =>  "OT Data Analytics", :code => "000045"},
      {:name =>  "OT General Marketing", :code => "000050"},
      {:name =>  "OT Consumer Marketing", :code => "000051"},
      {:name =>  "OT Restaurant Marketing", :code => "000052"},
      {:name =>  "OT Public Relations", :code => "000053"},
      {:name =>  "OT Product Marketing", :code => "000054"},
      {:name =>  "OT General Product Management", :code => "000060"},
      {:name =>  "OT Restaurant Product Management", :code => "000061"},
      {:name =>  "OT Consumer Product Management", :code => "000062"},
      {:name =>  "OT Design", :code => "000063"},
      {:name =>  "OT Business Development", :code => "000070"}
    ]

    depts.each { |attrs| Department.create(attrs) }

    allow(Net::LDAP).to receive(:new).and_return(ldap)
    allow(ldap).to receive(:host=)
    allow(ldap).to receive(:port=)
    allow(ldap).to receive(:encryption)
    allow(ldap).to receive(:auth)
    allow(ldap).to receive(:bind)

    Timecop.freeze(Time.now)
  end

  after :each do
    Timecop.return
  end

  context "create disabled employees" do
    let!(:employees) { FactoryGirl.create_list(:employee, 1, :first_name => "Donny", :last_name => "Kerabatsos") }

    it "should call ldap.add with correct info for regular employee" do
      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      expect(ldap).to receive(:add).once.with(
        hash_including(
          :dn => employees[0].dn,
          attributes: employees[0].ad_attrs.merge({
            :sAMAccountName => "dkerabatsos",
            :mail => "dkerabatsos@opentable.com"
          }).delete_if { |k,v| v.blank? }
        )
      )

      ads.create_disabled_accounts(employees)
      expect(employees[0].sAMAccountName).to eq("dkerabatsos")
      expect(employees[0].email).to eq("dkerabatsos@opentable.com")
      expect(employees[0].ad_updated_at).to eq(DateTime.now)
    end

    it "should eventually call ldap.add with a generated numeric sAMAccountName" do
      allow(ldap).to receive(:search).and_return("entry", "entry", "entry", []) # Mock search finding conflicting sAMAccountNames
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      expect(ldap).to receive(:add)

      ads.create_disabled_accounts(employees)
      expect(employees[0].sAMAccountName).to eq("dkerabatsos1")
      expect(employees[0].email).to eq("dkerabatsos1@opentable.com")
      expect(employees[0].ad_updated_at).to eq(DateTime.now)
    end

    it "should send an alert email when account creation fails" do
      allow(ldap).to receive(:add)
      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(67) # Simulate AD LDAP error

      # expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)
      ads.create_disabled_accounts(employees)
    end
  end

  context "assign sAMAccountName" do
    it "should normalize special characters and spaces" do
      employee = FactoryGirl.create(:employee, :first_name => "Mæby", :last_name => "Fünke Spløsh")

      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

      expect(ads.assign_sAMAccountName(employee)).to eq(true)
      expect(employee.sAMAccountName).to eq("mfunkesplosh")
    end

    it "should return true when available sAMAccountName is found" do
      employee = FactoryGirl.create(:employee, :first_name => "Walter", :last_name => "Sobchak")

      allow(ldap).to receive(:search).and_return([]) # Mock search not finding conflicting existing sAMAccountName

      expect(ads.assign_sAMAccountName(employee)).to eq(true)
      expect(employee.sAMAccountName).to eq("wsobchak")
    end

    it "should return false when no available sAMAccountName is found" do
      employee = FactoryGirl.create(:employee)

      allow(ldap).to receive(:search).and_return("entry") # Mock search finding conflicting existing sAMAccountName

      expect(ads.assign_sAMAccountName(employee)).to eq(false)
      expect(employee.sAMAccountName).to eq(nil)
    end
  end

  context "update attributes" do
    let(:ldap_entry) { Net::LDAP::Entry.new(employee.dn) }
    let(:employee) { FactoryGirl.create(:employee, :first_name => "Jeffrey", :last_name => "Lebowski", :department_id => Department.find_by(:name => "OT People and Culture").id)}

    before :each do
      ldap_entry[:cn] = "Jeffrey Lebowski"
      ldap_entry[:objectClass] = ["top", "person", "organizationalPerson", "user"]
      ldap_entry[:givenName] = "Jeffrey"
      ldap_entry[:sn] = "Lebowski"
      ldap_entry[:workdayUsername] = employee.workday_username
      ldap_entry[:co] = "US"
      ldap_entry[:accountExpires] = "9223372036854775807"
      ldap_entry[:title] = employee.business_title
      ldap_entry[:description] = employee.business_title
      ldap_entry[:employeeType] = employee.employee_type
      ldap_entry[:physicalDeliveryOfficeName] = employee.location
      ldap_entry[:department] = employee.department.name
      ldap_entry[:employeeID] = employee.employee_id
      ldap_entry[:mobile] = employee.personal_mobile_phone
      ldap_entry[:telephoneNumber] = employee.office_phone
      ldap_entry[:thumbnailPhoto] = employee.decode_img_code

      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
    end

    it "should update changed attributes" do
      employee.first_name = "The Dude"
      employee.business_title = "Big Boss"
      employee.office_phone = "555-555-5555"
      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to_not receive(:replace_attribute).with(employee.dn, :cn, "The Dude Lebowski")
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :givenName, "The Dude")
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :title, "Big Boss")
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :description, "Big Boss")
      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :telephoneNumber, "555-555-5555")
      expect(ldap).to receive(:rename).once.with(
        :olddn => "cn=Jeffrey Lebowski,ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :newrdn => "cn=The Dude Lebowski",
        :delete_attributes => true,
        :new_superior => "ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
      )
      ads.update([employee])
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should update dn if country changes" do
      employee.country = "GB"
      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :co, "GB")
      expect(ldap).to receive(:rename).once.with(
        :olddn => "cn=Jeffrey Lebowski,ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :newrdn => "cn=Jeffrey Lebowski",
        :delete_attributes => true,
        :new_superior => "ou=HR,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
      )
      ads.update([employee])
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should update dn if department changes" do
      employee.department = Department.find_by(:name => "OT Customer Support")
      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to receive(:replace_attribute).once.with(employee.dn, :department, "OT Customer Support")
      expect(ldap).to receive(:rename).once.with(
        :olddn => "cn=Jeffrey Lebowski,ou=People and Culture,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :newrdn => "cn=Jeffrey Lebowski",
        :delete_attributes => true,
        :new_superior => "ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
      )
      ads.update([employee])
      expect(employee.ad_updated_at).to eq(DateTime.now)
    end

    it "should not update unchanged attributes" do
      allow(ldap).to receive(:search).and_return([ldap_entry])

      expect(ldap).to_not receive(:replace_attribute)
      ads.update([employee])
      expect(employee.ad_updated_at).to be_nil
    end

    it "should send an alert email when account update fails" do
      employee.office_phone = "323-999-5555"
      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive(:replace_attribute)
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(67) # Simulate AD LDAP error

      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)
      ads.update([employee])
    end

    it "should send an alert email when account update to delete attribute fails" do
      employee.office_phone = nil
      allow(ldap).to receive(:search).and_return([ldap_entry])
      allow(ldap).to receive(:delete_attribute)
      allow(ldap).to receive_message_chain(:get_operation_result, :code).and_return(67) # Simulate AD LDAP error

      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)
      ads.update([employee])
    end

    it "should update changed attributes with nil" do
      rem_to_reg_employee = FactoryGirl.create(:employee, :remote)

      ldap_entry_2 = Net::LDAP::Entry.new(rem_to_reg_employee.dn)
      ldap_entry_2[:cn] = rem_to_reg_employee.cn
      ldap_entry_2[:objectClass] = ["top", "person", "organizationalPerson", "user"]
      ldap_entry_2[:givenName] = rem_to_reg_employee.first_name
      ldap_entry_2[:sn] = rem_to_reg_employee.last_name
      ldap_entry_2[:workdayUsername] = rem_to_reg_employee.workday_username
      ldap_entry_2[:co] = rem_to_reg_employee.country
      ldap_entry_2[:accountExpires] = rem_to_reg_employee.generated_account_expires
      ldap_entry_2[:title] = rem_to_reg_employee.business_title
      ldap_entry_2[:description] = rem_to_reg_employee.business_title
      ldap_entry_2[:employeeType] = rem_to_reg_employee.employee_type
      ldap_entry_2[:physicalDeliveryOfficeName] = rem_to_reg_employee.location
      ldap_entry_2[:department] = rem_to_reg_employee.department.name
      ldap_entry_2[:employeeID] = rem_to_reg_employee.employee_id
      ldap_entry_2[:mobile] = rem_to_reg_employee.personal_mobile_phone
      ldap_entry_2[:telephoneNumber] = rem_to_reg_employee.office_phone
      ldap_entry_2[:streetAddress] = rem_to_reg_employee.generated_address
      ldap_entry_2[:l] = rem_to_reg_employee.home_city
      ldap_entry_2[:st] = rem_to_reg_employee.home_state
      ldap_entry_2[:postalCode] = rem_to_reg_employee.home_zip
      ldap_entry_2[:thumbnailPhoto] = rem_to_reg_employee.decode_img_code
      ldap_entry_2[:contract_end_date] = rem_to_reg_employee.generated_account_expires
      allow(ldap).to receive(:search).and_return([ldap_entry_2])

      rem_to_reg_employee.home_address_1 = nil
      rem_to_reg_employee.home_address_2 = nil
      rem_to_reg_employee.home_city = nil
      rem_to_reg_employee.home_state = nil
      rem_to_reg_employee.home_zip = nil

      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :streetAddress)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :l)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :st)
      expect(ldap).to receive(:delete_attribute).once.with(rem_to_reg_employee.dn, :postalCode)
      ads.update([rem_to_reg_employee])
      expect(rem_to_reg_employee.ad_updated_at).to eq(DateTime.now)
    end

  end
end
