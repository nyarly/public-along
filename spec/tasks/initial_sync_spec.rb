require 'rails_helper'
require 'rake'

# This code is no longer in use
# Retaining specs for reference
xdescribe "initial sync rake task", type: :tasks do
  context "sync:csv['some/path']" do
    # create managers for the csv to reference
    let!(:manager_1) { FactoryGirl.create(:employee, employee_id: "12500096", sam_account_name: "samaccountname1", email: "email1")}
    let!(:manager_2) { FactoryGirl.create(:employee, employee_id: "12100784", sam_account_name: "samaccountname2", email: "email2")}
    let!(:manager_3) { FactoryGirl.create(:employee, employee_id: "12101112", sam_account_name: "samaccountname3", email: "email3")}
    let!(:manager_4) { FactoryGirl.create(:employee, employee_id: "1209012", sam_account_name: "samaccountname4", email: "email4")}
    let!(:job_title_1) { FactoryGirl.create(:job_title, name: "Account Executive")}
    let!(:job_title_2) { FactoryGirl.create(:job_title, name: "Inside Sales Associate")}
    let!(:job_title_3) { FactoryGirl.create(:job_title, name: "Inside Sales Representative")}
    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/initial_sync", [Rails.root.to_s], ''
      Rake::Task.define_task :environment

      @ldap_entry_1 = Net::LDAP::Entry.new("cn=Sir Mighty-Dinosaur,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "Sir Mighty-Dinosaur",
        dn: "cn=Sir Mighty-Dinosaur,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Sir",
        sn: "Mighty-Dinosaur",
        sAMAccountName: "smighty",
        displayName: "Sir Mighty-Dinosaur",
        userPrincipalName: "smighty@opentable.com",
        manager: manager_1.dn,
        workdayUsername: nil,
        co: "DE",
        accountExpires: "9223372036854775807",
        title: job_title_1.name,
        description: job_title_1.name,
        employeeType: "Regular",
        physicalDeliveryOfficeName: "Frankfurt Office",
        department: "Sales",
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
        displayName: "Kevin Smith",
        userPrincipalName: "ksmith@opentable.com",
        manager: manager_2.dn,
        workdayUsername: nil,
        co: "US",
        accountExpires: "9223372036854775807",
        title: job_title_2.name,
        description: job_title_2.name,
        employeeType: "Regular",
        physicalDeliveryOfficeName: "Colorado",
        department: "Inside Sales",
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
        displayName: "Maria Luigi Whoops",
        userPrincipalName: "mwhoops@opentable.com",
        manager: manager_3.dn,
        workdayUsername: nil,
        co: "GB",
        accountExpires: "9223372036854775807",
        title: job_title_3.name,
        description: job_title_3.name,
        employeeType: "Regular",
        physicalDeliveryOfficeName: "London Office",
        department: "Inside Sales",
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
      allow(@ldap).to receive(:rename)

      allow(ManagerMailer).to receive_message_chain(:permissions, :deliver_now)
    end

    it "should raise an exception if no path is provided" do
      expect{
        Rake::Task["sync:csv"].invoke
      }.to raise_error("You must provide a path to a .csv file")
    end

    it "should create new employees in db" do
      allow(@ldap).to receive(:replace_attribute)
      # this sync can't create job titles with proper codes and so will receive deletes for title and description for each record
      allow(@ldap).to receive(:delete_attribute)

      expect{
        Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      }.to change{ Employee.count }.by(5)
    end

    it "should not create employees with invalid data" do
      allow(@ldap).to receive(:replace_attribute)
      # this sync can't create job titles with proper codes and so will receive deletes for title and description for each record
      allow(@ldap).to receive(:delete_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Mario,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12101108")

      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(Employee.find_by(:first_name => "Mario")).to be_nil
    end

    it "should call AD update for employeeID with valid employees that have emails" do
      allow(@ldap).to receive(:replace_attribute).with("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :streetAddress, "1171 East 1st Ave #1234")
      # this sync can't create job titles with proper codes and so will receive deletes for title and description for each record
      allow(@ldap).to receive(:delete_attribute)


      expect(@ldap).to receive(:replace_attribute).with("cn=Sir Mighty-Dinosaur,ou=DE Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12100011")
      expect(@ldap).to receive(:replace_attribute).with("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12101767")
      expect(@ldap).to receive(:replace_attribute).with("cn=Maria Luigi Whoops,ou=UK Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :employeeID, "12101107")

      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
    end

    it "should save to DB, but not call AD update with valid employees that have no email" do
      allow(@ldap).to receive(:replace_attribute)
      # this sync can't create job titles with proper codes and so will receive deletes for title and description for each record
      allow(@ldap).to receive(:delete_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Luddite Johnson,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(Employee.find_by(:first_name => "Luddite")).to be_present
    end

    it "should error if the employee does not yet exist in AD" do
      allow(@ldap).to receive(:replace_attribute)
      # this sync can't create job titles with proper codes and so will receive deletes for title and description for each record
      allow(@ldap).to receive(:delete_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Non Existent,ou=Legal,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      expect(TechTableMailer).to receive_message_chain(:alert_email, :deliver_now)
      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(ActionMailer::Base.deliveries.last.parts.first.body.raw_source).to include("User not found in Active Directory. Update failed.")
    end

    xit "should not save home addresses in DB or AD unless it's a remote location" do
      # this sync can't create job titles with proper codes and so will receive deletes for title and description for each record
      allow(@ldap).to receive(:delete_attribute)

      expect(@ldap).to_not receive(:replace_attribute).with("cn=Sir Mighty-Dinosaur,ou=DE Sales,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :streetAddress, "Am Schlosspark 67")
      expect(@ldap).to     receive(:replace_attribute).with("cn=Kevin Smith,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :streetAddress, "1171 East 1st Ave #1234")

      Rake::Task["sync:csv"].invoke(Rails.root.to_s+'/spec/fixtures/test_sync.csv')
      expect(Employee.where(:email => "smighty@opentable.com")[0].home_address_1).to be_nil
      expect(Employee.where(:email => "ksmith@opentable.com")[0].home_address_1).to eq("1171 East 1st Ave #1234")
    end
  end
end
