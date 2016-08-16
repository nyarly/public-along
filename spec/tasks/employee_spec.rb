require 'rails_helper'
require 'rake'

describe "employee rake tasks", type: :tasks do

  let!(:london) { Location.find_by(:name => "OT London") }
  let!(:sf) { Location.find_by(:name => "OT San Francisco") }
  let!(:la) { Location.find_by(:name => "OT Los Angeles") }
  let!(:mumbai) { Location.find_by(:name => "OT Mumbai") }
  let!(:melbourne) { Location.find_by(:name => "OT Melbourne") }
  let!(:illinois) { Location.find_by(:name => "OT Illinois") }

  context "employee:change_status" do
    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/employee", [Rails.root.to_s], ''
      Rake::Task.define_task :environment

      @ldap = double(Net::LDAP)

      allow(Net::LDAP).to receive(:new).and_return(@ldap)
      allow(@ldap).to receive(:host=)
      allow(@ldap).to receive(:port=)
      allow(@ldap).to receive(:encryption)
      allow(@ldap).to receive(:auth)
      allow(@ldap).to receive(:bind)
    end

    after :each do
      Timecop.return
    end

    it "should call ldap and update only GB new hires and returning leave workers at 3am BST" do
      new_hire_uk = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :location_id => london.id)
      returning_uk = FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.new(2016, 7, 29), :location_id => london.id)

      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :location_id => sf.id)
      returning_us = FactoryGirl.create(:employee, :hire_date => 1.year.ago, :leave_return_date => Date.new(2016, 7, 29), :location_id => sf.id)
      termination = FactoryGirl.create(:employee, :contract_end_date => Date.new(2016, 7, 29), :location_id => london.id)

      # 7/29/2016 at 3am BST/2am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 2, 0, 0, "+00:00"))

      sec_prof = FactoryGirl.create(:security_profile)
      emp_trans_1 = FactoryGirl.create(:emp_transaction)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: new_hire_uk.id, security_profile_id: sec_prof.id)
      emp_trans_2 = FactoryGirl.create(:emp_transaction)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_2.id, employee_id: returning_uk.id, security_profile_id: sec_prof.id)

      expect(@ldap).to receive(:replace_attribute).once.with(
        new_hire_uk.dn, :userAccountControl, "512"
      )
      expect(@ldap).to receive(:replace_attribute).once.with(
        returning_uk.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        returning_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        termination.dn, :userAccountControl, "514"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke
    end

    it "should call ldap and update only US new hires and returning leave workers at 3am PST" do
      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :location_id => sf.id)
      returning_us = FactoryGirl.create(:employee, :hire_date => 5.years.ago, :leave_return_date => Date.new(2016, 7, 29), :location_id => sf.id)

      new_hire_uk = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :location_id => london.id)
      returning_uk = FactoryGirl.create(:employee, :hire_date => 5.years.ago, :leave_return_date => Date.new(2016, 7, 29), :location_id => london.id)
      termination = FactoryGirl.create(:employee, :contract_end_date => Date.new(2016, 7, 29), :location_id => sf.id)

      # 7/29/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 10, 0, 0, "+00:00"))

      sec_prof = FactoryGirl.create(:security_profile)
      emp_trans_1 = FactoryGirl.create(:emp_transaction)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: new_hire_us.id, security_profile_id: sec_prof.id)
      emp_trans_2 = FactoryGirl.create(:emp_transaction)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_2.id, employee_id: returning_us.id, security_profile_id: sec_prof.id)

      expect(@ldap).to receive(:replace_attribute).once.with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to receive(:replace_attribute).once.with(
       returning_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_uk.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        returning_uk.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        termination.dn, :userAccountControl, "514"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke
    end

    it "should call ldap and update only terminations or workers on leave at 9pm in IST" do
      termination = FactoryGirl.create(:employee, :hire_date => Date.new(2014, 5, 3), :contract_end_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "OT General Engineering").id, :location_id => mumbai.id)
      leave = FactoryGirl.create(:employee, :hire_date => Date.new(2014, 5, 3), :leave_start_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "OT Data Center Ops").id, :location_id => mumbai.id)
      new_hire_in = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "OT Data Analytics").id, :location_id => mumbai.id)
      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :location_id => sf.id)

      # 7/29/2016 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      expect(@ldap).to receive(:replace_attribute).once.with(
        termination.dn, :userAccountControl, "514"
      )
      expect(@ldap).to receive(:rename).once.with({
        :olddn=>termination.dn,
        :newrdn=>"cn=#{termination.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"})
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_in.dn, :userAccountControl, "512"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke
    end
  end

  context "employee:xml_to_ad" do
    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/employee", [Rails.root.to_s], ''
      Rake::Task.define_task :environment

      @ldap = double(Net::LDAP)

      allow(Net::LDAP).to receive(:new).and_return(@ldap)
      allow(@ldap).to receive(:host=)
      allow(@ldap).to receive(:port=)
      allow(@ldap).to receive(:encryption)
      allow(@ldap).to receive(:auth)
      allow(@ldap).to receive(:bind)
      allow(@ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      Employee.create(
      :first_name => "The Big",
      :last_name => "Lebowski",
      :workday_username => "biglebowski",
      :employee_id => "1234567",
      :hire_date => DateTime.new(2005,2,1),
      :contract_end_date => nil,
      :termination_date => nil,
      :job_family_id => "OT_Internal_Systems",
      :job_family => "OT Internal Systems",
      :job_profile_id => "50100486",
      :job_profile => "OT Internal Systems",
      :business_title => "Rich Guy",
      :employee_type => "Regular",
      :contingent_worker_type => nil,
      :location_id => la.id,
      :manager_id => "12100123",
      :department_id => Department.find_by(:name => "OT Business Optimization").id,
      :office_phone => nil,
      :image_code => nil)

      Employee.create(
      :first_name => "Kylie",
      :last_name => "Kylie",
      :workday_username => "kkylie",
      :employee_id => "109843",
      :hire_date => DateTime.new(2016,4,7),
      :contract_end_date => nil,
      :termination_date => nil,
      :job_family_id => "OT_Legal",
      :job_family => "OT Legal",
      :job_profile_id => "50100324",
      :job_profile => "OT Legal",
      :business_title => "OT Fraud Analyst",
      :employee_type => "Regular",
      :contingent_worker_type => nil,
      :location_id => melbourne.id,
      :manager_id => "12101034",
      :department_id => Department.find_by(:name => "OT Legal").id,
      :office_phone => "(213) 555-1234",
      :image_code => nil)

      @ldap_entry_1 = Net::LDAP::Entry.new("cn=The Big Lebowski,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "The Big Lebowski",
        dn: "cn=The Big Lebowski,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "The Big",
        sn: "Lebowski",
        sAMAccountName: "tlebowski",
        workdayUsername: "biglebowski",
        co: "US",
        accountExpires: "9223372036854775807",
        title: "Rich Guy",
        description: "Rich Guy",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "OT Los Angeles",
        department: "OT Business Optimization",
        employeeID: "1234567",
        mobile: nil,
        telephoneNumber: nil,
        streetAddress: nil,
        l: nil,
        st: nil,
        postalCode: nil,
        thumbnailPhoto: nil
      }.each { |k,v| @ldap_entry_1[k] = v }

      @ldap_entry_2 = Net::LDAP::Entry.new("cn=Kylie Kylie,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "Kylie Kylie",
        dn: "cn=Kylie Kylie,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Kylie",
        sn: "Kylie",
        sAMAccountName: "kkylie",
        workdayUsername: "kkylie",
        co: "AU",
        accountExpires: "9223372036854775807",
        title: "OT Fraud Analyst",
        description: "OT Fraud Analyst",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "OT Melbourne",
        department: "OT Legal",
        employeeID: "109843",
        mobile: nil,
        telephoneNumber: "(213) 555-1234",
        streetAddress: nil,
        l: nil,
        st: nil,
        postalCode: nil,
        thumbnailPhoto: nil
      }.each { |k,v| @ldap_entry_2[k] = v }
    end

    it "should pick up the correct xml file" do
      expect(File).to receive(:new).with("lib/assets/test_20160523_135008.xml")
      Rake::Task["employee:xml_to_ad"].invoke
    end

    it "should not run the same file twice" do
      expect(File).to receive(:new).once.with("lib/assets/test_20160523_135008.xml")
      Rake::Task["employee:xml_to_ad"].invoke
      Rake::Task["employee:xml_to_ad"].invoke
    end

    it "should create/update the correct amount of Employees in DB and AD" do
      allow(@ldap).to receive(:search).and_return([], [], [], [@ldap_entry_1], [@ldap_entry_2])
      allow(@ldap).to receive(:replace_attribute)
      expect(@ldap).to receive(:add).once.with({
        :dn=>"cn=Jeffrey Lebowski,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :attributes=>{:cn=>"Jeffrey Lebowski",
          :objectclass=>["top", "person", "organizationalPerson", "user"],
          :givenName=>"Jeffrey",
          :sn=>"Lebowski",
          :sAMAccountName=>"jlebowski",
          :mail=>"jlebowski@opentable.com",
          :unicodePwd=>"\"\x001\x002\x003\x00O\x00p\x00e\x00n\x00t\x00a\x00b\x00l\x00e\x00\"\x00",
          :workdayUsername=>"jefflebowski",
          :co=>"US",
          :accountExpires=>"9223372036854775807",
          :title=>"Software Development Team Lead",
          :description=>"Software Development Team Lead",
          :employeeType=>"Regular",
          :physicalDeliveryOfficeName=>"OT Los Angeles",
          :department=>"OT Business Optimization",
          :employeeID=>"12100401",
          :telephoneNumber=>"(213) 555-4321"}})
      expect(@ldap).to receive(:add).once.with({
        :dn=>"cn=Walter Sobchak,ou=Product,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :attributes=>{:cn=>"Walter Sobchak",
          :objectclass=>["top",
          "person",
          "organizationalPerson",
          "user"],
          :givenName=>"Walter",
          :sn=>"Sobchak",
          :sAMAccountName=>"wsobchak",
          :unicodePwd=>"\"\x001\x002\x003\x00O\x00p\x00e\x00n\x00t\x00a\x00b\x00l\x00e\x00\"\x00",
          :workdayUsername=>"walters",
          :co=>"GB",
          :accountExpires=>"131117184000000000",
          :title=>"OT Contingent Position - Product Management",
          :description=>"OT Contingent Position - Product Management",
          :employeeType=>"Vendor",
          :physicalDeliveryOfficeName=>"OT London",
          :department=>"OT General Product Management",
          :employeeID=>"109640",
          :telephoneNumber=>"(213) 555-9876"}})
      expect(@ldap).to receive(:add).once.with({
        :dn=>"cn=Maude Lebowski,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :attributes=>{:cn=>"Maude Lebowski",
          :objectclass=>["top", "person", "organizationalPerson", "user"],
          :givenName=>"Maude",
          :sn=>"Lebowski",
          :sAMAccountName=>"mlebowski",
          :mail=>"mlebowski@opentable.com",
          :unicodePwd=>"\"\x001\x002\x003\x00O\x00p\x00e\x00n\x00t\x00a\x00b\x00l\x00e\x00\"\x00",
          :workdayUsername=>"12101234",
          :co=>"US",
          :accountExpires=>"9223372036854775807",
          :title=>"OT Account Executive",
          :description=>"OT Account Executive",
          :employeeType=>"Regular",
          :physicalDeliveryOfficeName=>"OT Illinois",
          :department=>"OT Sales - General",
          :employeeID=>"12101234",
          :telephoneNumber=>"(213) 555-4321",
          :streetAddress=>"123 East Side, #2310",
          :l=>"Chicago",
          :st=>"Illinois",
          :postalCode=>"60611",
          :thumbnailPhoto=>Base64.decode64(IMAGE)}})
      expect(@ldap).to receive(:replace_attribute).once.with("cn=The Big Lebowski,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :telephoneNumber, "(213) 555-4321")
      expect(@ldap).to receive(:replace_attribute).once.with("cn=Kylie Kylie,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :accountExpires, "131061888000000000")
      expect{
        expect{
          Rake::Task["employee:xml_to_ad"].invoke
        }.to change{ Employee.count }.from(2).to(5)
      }.to change{ XmlTransaction.count }.from(0).to(1)
      expect(XmlTransaction.last.name).to eq("test_20160523_135008.xml")
      expect(XmlTransaction.last.checksum).to eq(Digest::MD5.hexdigest(File.read("lib/assets/test_20160523_135008.xml")))
    end
  end
end
