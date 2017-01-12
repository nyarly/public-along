require 'rails_helper'
require 'rake'

describe "employee rake tasks", type: :tasks do

  let!(:london) { Location.find_by(:name => "London Office") }
  let!(:sf) { Location.find_by(:name => "San Francisco Headquarters") }
  let!(:la) { Location.find_by(:name => "Los Angeles Office") }
  let!(:mumbai) { Location.find_by(:name => "Mumbai Office") }
  let!(:melbourne) { Location.find_by(:name => "Melbourne Office") }
  let!(:illinois) { Location.find_by(:name => "Illinois") }

  let(:mailer) { double(ManagerMailer) }

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
      emp_trans_1 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      onboarding_info_1 = FactoryGirl.create(:onboarding_info, employee_id: new_hire_uk.id, emp_transaction_id: emp_trans_1.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: new_hire_uk.id, security_profile_id: sec_prof.id)
      emp_trans_2 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      onboarding_info_2 = FactoryGirl.create(:onboarding_info, employee_id: returning_uk.id, emp_transaction_id: emp_trans_2.id)
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
      emp_trans_1 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      onboarding_info_1 = FactoryGirl.create(:onboarding_info, employee_id: new_hire_us.id, emp_transaction_id: emp_trans_1.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: new_hire_us.id, security_profile_id: sec_prof.id)
      emp_trans_2 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      onboarding_info_2 = FactoryGirl.create(:onboarding_info, employee_id: returning_us.id, emp_transaction_id: emp_trans_2.id)
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
      contract_end = FactoryGirl.create(:employee, :hire_date => Date.new(2014, 5, 3), :contract_end_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "Technology/CTO Admin").id, :location_id => mumbai.id)
      termination = FactoryGirl.create(:employee, :hire_date => Date.new(2014, 5, 3), :termination_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "Technology/CTO Admin").id, :location_id => mumbai.id)
      leave = FactoryGirl.create(:employee, :hire_date => Date.new(2014, 5, 3), :leave_start_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "Infrastructure Engineering").id, :location_id => mumbai.id)
      new_hire_in = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "Data Analytics & Experimentation").id, :location_id => mumbai.id)
      new_hire_us = FactoryGirl.create(:employee, :hire_date => Date.new(2016, 7, 29), :location_id => sf.id)

      # 7/29/2016 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      expect(@ldap).to receive(:replace_attribute).once.with(
        contract_end.dn, :userAccountControl, "514"
      )
      expect(@ldap).to receive(:rename).once.with({
        :olddn=>contract_end.dn,
        :newrdn=>"cn=#{contract_end.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"})
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

    it "should remove worker from all security groups at 3am, 30 days after termination" do
      termination = FactoryGirl.create(:employee, :manager_id => "12345", :hire_date => Date.new(2014, 5, 3), :termination_date => Date.new(2016, 7, 29), :department_id => Department.find_by(:name => "Technology/CTO Admin").id, :location_id => sf.id)
      recent_termination = FactoryGirl.create(:employee, :manager_id => "12345", :hire_date => Date.new(2014, 5, 3), :termination_date => Date.new(2016, 8, 20), :department_id => Department.find_by(:name => "Technology/CTO Admin").id, :location_id => sf.id)
      manager = FactoryGirl.create(:employee, :employee_id => "12345")

      app_1 = FactoryGirl.create(:application)
      app_2 = FactoryGirl.create(:application)
      sec_prof = FactoryGirl.create(:security_profile)
      access_level_1 = FactoryGirl.create(:access_level, application_id: app_1.id, ad_security_group: "sec_dn_1")
      sec_prof_access_level_2 = FactoryGirl.create(:sec_prof_access_level, access_level_id: access_level_1.id, security_profile_id: sec_prof.id)
      access_level_2 = FactoryGirl.create(:access_level, application_id: app_2.id, ad_security_group: "sec_dn_2")
      sec_prof_access_level_2 = FactoryGirl.create(:sec_prof_access_level, access_level_id: access_level_2.id, security_profile_id: sec_prof.id)

      # Add security profile for termination worker
      emp_trans_1 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_1.id, employee_id: termination.id, security_profile_id: sec_prof.id)

      # Add security profile for recent_termination worker
      emp_trans_2 = FactoryGirl.create(:emp_transaction, kind: "Onboarding")
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_trans_2.id, employee_id: recent_termination.id, security_profile_id: sec_prof.id)

      # 8/28/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 8, 28, 10, 0, 0, "+00:00"))
      allow(@ldap).to receive_message_chain(:get_operation_result, :code).and_return(0)

      expect(@ldap).to receive(:modify).once.ordered.with({:dn => "sec_dn_1", :operations => [[:delete, :member, termination.dn]]})
      expect(@ldap).to receive(:modify).once.ordered.with({:dn => "sec_dn_2", :operations => [[:delete, :member, termination.dn]]})
      expect(@ldap).to_not receive(:modify).with({:dn => "sec_dn_1", :operations => [[:delete, :member, recent_termination.dn]]})
      expect(@ldap).to_not receive(:modify).with({:dn => "sec_dn_2", :operations => [[:delete, :member, recent_termination.dn]]})
      Rake::Task["employee:change_status"].invoke
    end
  end

  context "Employee event reports" do
    let(:mailer) { double(SummaryReportMailer) }

    it "should send onboarding report" do
      expect(SummaryReportMailer).to receive(:onboard_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["employee:onboard_report"].invoke
    end

    it "should send offboarding report" do
      expect(SummaryReportMailer).to receive(:offboard_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["employee:offboard_report"].invoke
    end

    it "should send job change report if EmpDelta.report_group count > 0" do
      expect(EmpDelta).to receive_message_chain(:report_group, :count).and_return(4)
      expect(SummaryReportMailer).to receive(:job_change_report).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      Rake::Task["employee:job_change_report"].invoke
    end

    it "should send job change report if EmpDelta.report_group count = 0" do
      expect(EmpDelta).to receive_message_chain(:report_group, :count).and_return(0)
      expect(SummaryReportMailer).to_not receive(:job_change_report)
      Rake::Task["employee:job_change_report"].execute
    end
  end

  context "employee:xml_to_ad" do
    # create managers for the xml to reference
    let!(:manager_1) { FactoryGirl.create(:employee, employee_id: "12100123", sam_account_name: "samaccountname1")}
    let!(:manager_2) { FactoryGirl.create(:employee, employee_id: "12101502", sam_account_name: "samaccountname2")}
    let!(:manager_3) { FactoryGirl.create(:employee, employee_id: "12100567", sam_account_name: "samaccountname3")}
    let!(:manager_4) { FactoryGirl.create(:employee, employee_id: "12101034", sam_account_name: "samaccountname4")}

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
      :job_family => "Internal Systems",
      :job_profile_id => "50100486",
      :job_profile => "Internal Systems",
      :business_title => "Rich Guy",
      :employee_type => "Regular",
      :contingent_worker_type => nil,
      :location_id => la.id,
      :manager_id => "12100123",
      :department_id => Department.find_by(:name => "BizOpti/Internal Systems Engineering").id,
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
      :job_family => "Legal",
      :job_profile_id => "50100324",
      :job_profile => "Legal",
      :business_title => "Fraud Analyst",
      :employee_type => "Regular",
      :contingent_worker_type => nil,
      :location_id => melbourne.id,
      :manager_id => "12101034",
      :department_id => Department.find_by(:name => "Legal").id,
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
        displayName: "The Big Lebowski",
        userPrincipalName: "tlebowski@opentable.com",
        sAMAccountName: "tlebowski",
        manager: manager_1.dn,
        workdayUsername: "biglebowski",
        co: "US",
        accountExpires: "9223372036854775807",
        title: "Rich Guy",
        description: "Rich Guy",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "Los Angeles Office",
        department: "BizOpti/Internal Systems Engineering",
        employeeID: "1234567",
        mobile: nil,
        telephoneNumber: nil,
        streetAddress: nil,
        l: nil,
        st: nil,
        postalCode: nil,
        thumbnailPhoto: nil
      }.each { |k,v| @ldap_entry_1[k] = v }

      @ldap_entry_2 = Net::LDAP::Entry.new("cn=Kylie Kylie,ou=OT,dc=ottest,dc=opentable,dc=com")
      {
        cn: "Kylie Kylie",
        dn: "cn=Kylie Kylie,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Kylie",
        sn: "Kylie",
        sAMAccountName: "kkylie",
        displayName: "Kylie Kylie",
        userPrincipalName: "kkylie@opentable.com",
        workdayUsername: "kkylie",
        co: "AU",
        accountExpires: "9223372036854775807",
        title: "Fraud Analyst",
        description: "Fraud Analyst",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "Melbourne Office",
        department: "Legal",
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
          :displayName=>"Jeffrey Lebowski",
          :userPrincipalName=>"jlebowski@opentable.com",
          :manager=>manager_1.dn,
          :mail=>"jlebowski@opentable.com",
          :unicodePwd=>"\"\x001\x002\x003\x00O\x00p\x00e\x00n\x00t\x00a\x00b\x00l\x00e\x00\"\x00",
          :workdayUsername=>"jefflebowski",
          :co=>"US",
          :accountExpires=>"9223372036854775807",
          :title=>"Software Development Team Lead",
          :description=>"Software Development Team Lead",
          :employeeType=>"Regular",
          :physicalDeliveryOfficeName=>"Los Angeles Office",
          :department=>"BizOpti/Internal Systems Engineering",
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
          :displayName=>"Walter Sobchak",
          :userPrincipalName=>"wsobchak@opentable.com",
          :manager=>manager_2.dn,
          :unicodePwd=>"\"\x001\x002\x003\x00O\x00p\x00e\x00n\x00t\x00a\x00b\x00l\x00e\x00\"\x00",
          :workdayUsername=>"walters",
          :co=>"GB",
          :accountExpires=>"131117904000000000",
          :title=>"Contingent Position - Product Management",
          :description=>"Contingent Position - Product Management",
          :employeeType=>"Vendor",
          :physicalDeliveryOfficeName=>"London Office",
          :department=>"Consumer Product Management",
          :employeeID=>"109640",
          :telephoneNumber=>"(213) 555-9876"}})
      expect(@ldap).to receive(:add).once.with({
        :dn=>"cn=Maude Lebowski,ou=Sales,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        :attributes=>{:cn=>"Maude Lebowski",
          :objectclass=>["top", "person", "organizationalPerson", "user"],
          :givenName=>"Maude",
          :sn=>"Lebowski",
          :sAMAccountName=>"mlebowski",
          :displayName=>"Maude Lebowski",
          :userPrincipalName=>"mlebowski@opentable.com",
          :manager=>manager_3.dn,
          :mail=>"mlebowski@opentable.com",
          :unicodePwd=>"\"\x001\x002\x003\x00O\x00p\x00e\x00n\x00t\x00a\x00b\x00l\x00e\x00\"\x00",
          :workdayUsername=>"12101234",
          :co=>"US",
          :accountExpires=>"9223372036854775807",
          :title=>"Account Executive",
          :description=>"Account Executive",
          :employeeType=>"Regular",
          :physicalDeliveryOfficeName=>"Illinois",
          :department=>"Sales",
          :employeeID=>"12101234",
          :telephoneNumber=>"(213) 555-4321",
          :streetAddress=>"123 East Side, #2310",
          :l=>"Chicago",
          :st=>"Illinois",
          :postalCode=>"60611",
          :thumbnailPhoto=>Base64.decode64(IMAGE)}})
      expect(@ldap).to receive(:replace_attribute).once.with("cn=The Big Lebowski,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :telephoneNumber, "(213) 555-4321")
      expect(@ldap).to receive(:replace_attribute).once.with("cn=Kylie Kylie,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :accountExpires, "131062266000000000")
      expect{
        expect{
          Rake::Task["employee:xml_to_ad"].invoke
        }.to change{ Employee.count }.from(6).to(9)
      }.to change{ XmlTransaction.count }.from(0).to(1)
      expect(XmlTransaction.last.name).to eq("test_20160523_135008.xml")
      expect(XmlTransaction.last.checksum).to eq(Digest::MD5.hexdigest(File.read("lib/assets/test_20160523_135008.xml")))
    end
  end
end
