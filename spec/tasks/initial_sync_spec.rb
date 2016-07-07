require 'rails_helper'
require 'rake'

describe "initial sync rake task", type: :tasks do
  context "sync:csv['some/path']" do
    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/initial_sync", [Rails.root.to_s], ''
      Rake::Task.define_task :environment

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

      locs = [
        { :name => "OT San Francisco", :kind => "Office", :country => "US" },
        { :name => "OT Los Angeles", :kind => "Office", :country => "US" },
        { :name => "OT Denver", :kind => "Office", :country => "US" },
        { :name => "OT Chattanooga", :kind => "Office", :country => "US" },
        { :name => "OT Chicago", :kind => "Office", :country => "US" },
        { :name => "OT New York", :kind => "Office", :country => "US" },
        { :name => "OT Mexico City", :kind => "Office", :country => "MX" },
        { :name => "OT London", :kind => "Office", :country => "GB" },
        { :name => "OT Frankfurt", :kind => "Office", :country => "DE" },
        { :name => "OT Mumbai", :kind => "Office", :country => "IN" },
        { :name => "OT Tokyo", :kind => "Office", :country => "JP" },
        { :name => "OT Melbourne", :kind => "Office", :country => "AU" },
        { :name => "OT Arizona", :kind => "Remote Location", :country => "US" },
        { :name => "OT Colorado", :kind => "Remote Location", :country => "US" },
        { :name => "OT Illinois", :kind => "Remote Location", :country => "US" },
        { :name => "OT Tennessee", :kind => "Remote Location", :country => "US" },
        { :name => "OT Southern CA", :kind => "Remote Location", :country => "US" },
        { :name => "OT Minnesota", :kind => "Remote Location", :country => "US" },
        { :name => "OT Maine", :kind => "Remote Location", :country => "US" },
        { :name => "OT Georgia", :kind => "Remote Location", :country => "US" },
        { :name => "OT Canada", :kind => "Remote Location", :country => "CA" },
        { :name => "OT Washington DC", :kind => "Remote Location", :country => "US" },
        { :name => "OT Pennsylvania", :kind => "Remote Location", :country => "US" },
        { :name => "OT Oregon", :kind => "Remote Location", :country => "US" },
        { :name => "OT Wisconsin", :kind => "Remote Location", :country => "US" },
        { :name => "OT Texas", :kind => "Remote Location", :country => "US" },
        { :name => "OT Ohio", :kind => "Remote Location", :country => "US" },
        { :name => "OT Massachusetts", :kind => "Remote Location", :country => "US" },
        { :name => "OT Washington", :kind => "Remote Location", :country => "US" },
        { :name => "OT Florida", :kind => "Remote Location", :country => "US" },
        { :name => "OT Nevada", :kind => "Remote Location", :country => "US" },
        { :name => "OT New Jersey", :kind => "Remote Location", :country => "US" },
        { :name => "OT Hawaii", :kind => "Remote Location", :country => "US" },
        { :name => "OT Vermont", :kind => "Remote Location", :country => "US" },
        { :name => "OT Missouri", :kind => "Remote Location", :country => "US" },
        { :name => "OT Louisiana", :kind => "Remote Location", :country => "US" },
        { :name => "OT Michigan", :kind => "Remote Location", :country => "US" },
        { :name => "OT Ireland", :kind => "Remote Location", :country => "IE" },
        { :name => "OT North Carolina", :kind => "Remote Location", :country => "US" },
        { :name => "OT Idaho", :kind => "Remote Location", :country => "US" },
        { :name => "OT Maryland", :kind => "Remote Location", :country => "US" },
        { :name => "OT Utah", :kind => "Remote Location", :country => "US" },
        { :name => "OT Kentucky", :kind => "Remote Location", :country => "US" }
      ]

      locs.each { |attrs| Location.create(attrs) }

      @ldap_entry_1 = Net::LDAP::Entry.new("cn=Sir Mighty-Dinosaur,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "Sir Mighty-Dinosaur",
        dn: "cn=Sir Mighty-Dinosaur,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Sir",
        sn: "Mighty-Dinosaur",
        sAMAccountName: "smighty",
        workdayUsername: nil,
        co: "DE",
        accountExpires: "9223372036854775807",
        title: "Account Executive",
        description: "Account Executive",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "OT Frankfurt",
        department: "OT Sales - General",
        employeeID: nil,
        mobile: nil,
        telephoneNumber: nil,
        streetAddress: nil,
        l: nil,
        st: nil,
        postalCode: nil,
        thumbnailPhoto: nil
      }.each { |k,v| @ldap_entry_1[k] = v }

      @ldap_entry_2 = Net::LDAP::Entry.new("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "Kevin Smith",
        dn: "cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Kevin",
        sn: "Smith",
        sAMAccountName: "ksmith",
        workdayUsername: nil,
        co: "US",
        accountExpires: "9223372036854775807",
        title: "Inside Sales Associate",
        description: "Inside Sales Associate",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "OT Colorado",
        department: "OT Inside Sales",
        employeeID: nil,
        mobile: nil,
        telephoneNumber: "1 434 555-8878",
        streetAddress: nil,
        l: "Broomfield",
        st: "CO",
        postalCode: "80123",
        thumbnailPhoto: nil
      }.each { |k,v| @ldap_entry_2[k] = v }

      @ldap_entry_3 = Net::LDAP::Entry.new("cn=Maria Luigi Whoops,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "Maria Luigi Whoops",
        dn: "cn=Maria Luigi Whoops,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Maria Luigi",
        sn: "Whoops",
        sAMAccountName: "mwhoops",
        workdayUsername: nil,
        co: "GB",
        accountExpires: "9223372036854775807",
        title: "Inside Sales Representative",
        description: "Inside Sales Representative",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "OT London",
        department: "OT Inside Sales",
        employeeID: nil,
        mobile: nil,
        telephoneNumber: "44 0 222 4455 2250",
        streetAddress: nil,
        l: nil,
        st: nil,
        postalCode: nil,
        thumbnailPhoto: nil
      }.each { |k,v| @ldap_entry_3[k] = v }

      @ldap = double(Net::LDAP)

      allow(Net::LDAP).to receive(:new).and_return(@ldap)
      allow(@ldap).to receive(:host=)
      allow(@ldap).to receive(:port=)
      allow(@ldap).to receive(:encryption)
      allow(@ldap).to receive(:auth)
      allow(@ldap).to receive(:bind)
      allow(@ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)
      allow(@ldap).to receive(:search).and_return([@ldap_entry_1], [@ldap_entry_2], [@ldap_entry_3], [])
    end

    it "should raise an exception if no path is provided" do
      expect{
        Rake::Task["sync:csv"].invoke
      }.to raise_error("You must provide a path to a .csv file")
    end

    it "should create new employees in db" do
      allow(@ldap).to receive(:replace_attribute)

      expect{
        Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      }.to change{ Employee.count }.by(5)
    end

    it "should not create employees with invalid data" do
      allow(@ldap).to receive(:replace_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Mario,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12101108")

      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(Employee.find_by(:first_name => "Mario")).to be_nil
    end

    it "should call AD update for employeeID with valid employees that have emails" do
      allow(@ldap).to receive(:replace_attribute).with("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :streetAddress, "1171 East 1st Ave #1234")


      expect(@ldap).to receive(:replace_attribute).with("cn=Sir Mighty-Dinosaur,ou=DE Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12100011")
      expect(@ldap).to receive(:replace_attribute).with("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12101767")
      expect(@ldap).to receive(:replace_attribute).with("cn=Maria Luigi Whoops,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12101107")

      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
    end

    it "should save to DB, but not call AD update with valid employees that have no email" do
      allow(@ldap).to receive(:replace_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Luddite Johnson,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(Employee.find_by(:first_name => "Luddite")).to be_present
    end

    it "should error if the employee does not yet exist in AD" do
      allow(@ldap).to receive(:replace_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Non Existent,ou=Legal,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)
      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(ActionMailer::Base.deliveries.last.body).to include("User not found in Active Directory. Update failed.")
    end

    it "should not save home addresses in DB or AD unless it's a remote location" do

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Sir Mighty-Dinosaur,ou=DE Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :streetAddress, "Am Schlosspark 67")
      expect(@ldap).to     receive(:replace_attribute).with("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :streetAddress, "1171 East 1st Ave #1234")

      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(Employee.where(:email => "smighty@opentable.com")[0].home_address_1).to be_nil
      expect(Employee.where(:email => "ksmith@opentable.com")[0].home_address_1).to eq("1171 East 1st Ave #1234")
    end
  end
end
