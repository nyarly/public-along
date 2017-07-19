require 'rails_helper'
require 'rake'

describe "employee rake tasks", type: :tasks do

  let!(:london) { Location.find_by(name: "London Office") }
  let!(:sf) { Location.find_by(name: "San Francisco Headquarters") }
  let!(:la) { Location.find_by(name: "Los Angeles Office") }
  let!(:mumbai) { Location.find_by(name: "Mumbai Office") }
  let!(:melbourne) { Location.find_by(name: "Melbourne Office") }
  let!(:illinois) { Location.find_by(name: "Illinois") }
  let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Regular")}
  let!(:contract_worker_type) { FactoryGirl.create(:worker_type, kind: "Contractor") }

  let(:mailer) { double(ManagerMailer) }

  context "employee:change_status" do
    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/employee", [Rails.root.to_s], ''
      Rake::Task.define_task :environment

      @offboarding_service = double(OffboardingService)
      @ldap = double(Net::LDAP)
      @ldap_entry = double(Net::LDAP::Entry)

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
      new_hire_uk = FactoryGirl.create(:employee,
        status: "Pending",
        hire_date: Date.new(2016, 7, 29),
        location_id: london.id,
        worker_type_id: worker_type.id)
      returning_uk = FactoryGirl.create(:employee,
        status: "Inactive",
        hire_date: 1.year.ago,
        leave_return_date: Date.new(2016, 7, 29),
        location_id: london.id,
        worker_type_id: worker_type.id)
      contract_uk = FactoryGirl.create(:employee,
        status: "Active",
        contract_end_date: Date.new(2016, 7, 29),
        location_id: london.id,
        worker_type_id: contract_worker_type.id)

      new_hire_us = FactoryGirl.create(:employee,
        status: "Pending",
        hire_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)
      returning_us = FactoryGirl.create(:employee,
        status: "Inactive",
        hire_date: 1.year.ago,
        leave_return_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)

      # 7/29/2016 at 3am BST/2am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 2, 0, 0, "+00:00"))

      sec_prof = FactoryGirl.create(:security_profile)
      emp_trans_1 = FactoryGirl.create(:emp_transaction,
        employee_id: new_hire_uk.id,
        kind: "Onboarding")
      onboarding_info_1 = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans_1.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans_1.id,
        security_profile_id: sec_prof.id)
      emp_trans_2 = FactoryGirl.create(:emp_transaction,
        employee_id: returning_uk.id,
        kind: "Onboarding")
      onboarding_info_2 = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans_2.id)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans_2.id,
        security_profile_id: sec_prof.id)

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
        contract_uk.dn, :userAccountControl, "514"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke

      expect(new_hire_uk.reload.status).to eq("Active")
      expect(returning_uk.reload.status).to eq("Active")
      expect(contract_uk.reload.status).to eq("Active")
      expect(new_hire_us.reload.status).to eq("Pending")
      expect(returning_us.reload.status).to eq("Inactive")
    end

    it "should call ldap and update only US new hires and returning leave workers at 3am PST" do
      new_hire_us = FactoryGirl.create(:employee,
        status: "Pending",
        hire_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)
      returning_us = FactoryGirl.create(:employee,
        status: "Inactive",
        hire_date: 5.years.ago,
        leave_return_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)

      new_hire_uk = FactoryGirl.create(:employee,
        status: "Pending",
        hire_date: Date.new(2016, 7, 29),
        location_id: london.id,
        worker_type_id: worker_type.id)
      returning_uk = FactoryGirl.create(:employee,
        status: "Inactive",
        hire_date: 5.years.ago,
        leave_return_date: Date.new(2016, 7, 29),
        location_id: london.id,
        worker_type_id: worker_type.id)
      termination = FactoryGirl.create(:employee,
        status: "Active",
        contract_end_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)

      # 7/29/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 10, 0, 0, "+00:00"))

      sec_prof = FactoryGirl.create(:security_profile)
      emp_trans_1 = FactoryGirl.create(:emp_transaction,
        kind: "Onboarding",
        employee_id: new_hire_us.id)
      onboarding_info_1 = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans_1.id)
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans_1.id,
        security_profile_id: sec_prof.id)
      emp_trans_2 = FactoryGirl.create(:emp_transaction,
        kind: "Onboarding",
        employee_id: new_hire_uk.id)
      onboarding_info_2 = FactoryGirl.create(:onboarding_info,
        emp_transaction_id: emp_trans_2.id)
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans_2.id,
        security_profile_id: sec_prof.id)

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

      expect(new_hire_us.reload.status).to eq("Active")
      expect(returning_us.reload.status).to eq("Active")
      expect(new_hire_uk.reload.status).to eq("Pending")
      expect(returning_uk.reload.status).to eq("Inactive")
      expect(termination.reload.status).to eq("Active")
    end

    it "should call ldap and update only terminations or workers on leave at 9pm in PST" do

      termination_us = FactoryGirl.create(:employee,
        hire_date: 5.years.ago,
        status: "Active",
        termination_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)

      contract_end_us = FactoryGirl.create(:employee,
        hire_date: 5.years.ago,
        status: "Active",
        contract_end_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: contract_worker_type.id)

      leave_us = FactoryGirl.create(:employee,
        hire_date: 2.years.ago,
        status: "Active",
        leave_start_date: Date.new(2016, 7, 30),
        location_id: sf.id,
        worker_type_id: worker_type.id)

      # 7/29/2016 at 9pm PST/3am UTC
      Timecop.freeze(Time.new(2016, 7, 30, 4, 03, 0, "+00:00"))

      allow(@ldap).to receive(:search).and_return([@ldap_entry])
      allow(@ldap_entry).to receive(:dn).and_return("the old dn")

      expect(@ldap).to receive(:replace_attribute).thrice.with(
        "the old dn", :userAccountControl, "514"
      )

      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{termination_us.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com"})

      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{contract_end_us.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com"})

      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{leave_us.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com"})

      allow(@ldap).to receive(:get_operation_result)

      expect(OffboardingService).to receive(:new).and_return(@offboarding_service).once
      expect(@offboarding_service).to receive(:offboard).once.with([termination_us])
      Rake::Task["employee:change_status"].invoke

      expect(termination_us.reload.status).to eq("Terminated")
      expect(contract_end_us.reload.status).to eq("Terminated")
      # At the moment, users going on leave are being given a "Terminated" status
      # TODO: Investigate when ADP updates worker status to "Inactive" or "Terminated"
      # TODO: Move Mezzo worker status update elsewhere
      # expect(leave_us.reload.status).to eq("Inactive")
    end


    it "should call ldap and update only terminations or workers on leave at 9pm in IST" do
      contract_end = FactoryGirl.create(:employee,
        hire_date: Date.new(2014, 5, 3),
        contract_end_date: Date.new(2016, 7, 29),
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: mumbai.id,
        worker_type_id: contract_worker_type.id)
      termination = FactoryGirl.create(:employee,
        hire_date: Date.new(2014, 5, 3),
        termination_date: Date.new(2016, 7, 29),
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: mumbai.id,
        worker_type_id: worker_type.id)
      leave = FactoryGirl.create(:employee,
        hire_date: Date.new(2014, 5, 3),
        leave_start_date: Date.new(2016, 7, 29),
        department_id: Department.find_by(:name => "Infrastructure Engineering").id,
        location_id: mumbai.id,
        worker_type_id: worker_type.id)
      new_hire_in = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 29),
        department_id: Department.find_by(:name => "Data Analytics & Experimentation").id,
        location_id: mumbai.id,
        worker_type_id: worker_type.id)
      new_hire_us = FactoryGirl.create(:employee,
        hire_date: Date.new(2016, 7, 29),
        location_id: sf.id,
        worker_type_id: worker_type.id)

      # 7/29/2016 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      allow(@ldap).to receive(:search).and_return([@ldap_entry])
      allow(@ldap_entry).to receive(:dn).and_return("the old dn")
      expect(@ldap).to receive(:replace_attribute).once.with(
        "the old dn", :userAccountControl, "514"
      )
      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{contract_end.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com"})
      expect(@ldap).to receive(:replace_attribute).once.with(
        "the old dn", :userAccountControl, "514"
      )
      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{termination.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com"})
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_us.dn, :userAccountControl, "512"
      )
      expect(@ldap).to_not receive(:replace_attribute).with(
        new_hire_in.dn, :userAccountControl, "512"
      )

      allow(@ldap).to receive(:get_operation_result)

      expect(OffboardingService).to receive(:new).and_return(@offboarding_service).once
      expect(@offboarding_service).to receive(:offboard).once.with([termination])
      Rake::Task["employee:change_status"].invoke

      expect(contract_end.reload.status).to eq("Terminated")
      expect(termination.reload.status).to eq("Terminated")
      # expect(leave.reload.status).to eq("Inactive")
    end

    it "should offboard deactivated employee group at 9pm in IST" do
      termination = FactoryGirl.create(:employee,
        termination_date: Date.new(2016, 7, 29),
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: mumbai.id,
        worker_type_id: worker_type.id)

      # 7/29/ 2017 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      expect(OffboardingService).to receive(:new).and_return(@offboarding_service).once
      ad = double(ActiveDirectoryService)
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:deactivate)
      allow(ad).to receive(:activate)
      allow(ad).to receive(:terminate)
      expect(@offboarding_service).to receive(:offboard).once.with([termination])

      Rake::Task["employee:change_status"].invoke
    end

    it "should send tech table offboard instructions at noon on the termination day in IST" do
      manager = FactoryGirl.create(:employee, employee_id: "12345")

      termination = FactoryGirl.create(:employee,
        termination_date: Date.new(2016, 7, 29),
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: mumbai.id,
        worker_type_id: worker_type.id,
        manager_id: manager.employee_id)

        Timecop.freeze(Time.new(2016, 7, 29, 6, 30, 0, "+00:00"))

        expect(TechTableMailer).to receive_message_chain(:offboard_instructions, :deliver_now)
        Rake::Task["employee:change_status"].invoke
    end

    it "should remove worker from all security groups at 3am, 7 days after termination" do
      termination = FactoryGirl.create(:employee,
        manager_id: "12345",
        hire_date: Date.new(2014, 5, 3),
         termination_date: Date.new(2016, 8, 21),
         department_id: Department.find_by(:name => "Technology/CTO Admin").id,
         location_id: sf.id,
         worker_type_id: worker_type.id)
      recent_termination = FactoryGirl.create(:employee,
        manager_id: "12345",
        hire_date: Date.new(2014, 5, 3),
        termination_date: Date.new(2016, 8, 20),
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: sf.id,
        worker_type_id: worker_type.id)
      manager = FactoryGirl.create(:employee, employee_id: "12345")

      app_1 = FactoryGirl.create(:application)
      app_2 = FactoryGirl.create(:application)
      sec_prof = FactoryGirl.create(:security_profile)
      access_level_1 = FactoryGirl.create(:access_level,
        application_id: app_1.id,
        ad_security_group: "sec_dn_1")
      sec_prof_access_level_2 = FactoryGirl.create(:sec_prof_access_level,
        access_level_id: access_level_1.id,
        security_profile_id: sec_prof.id)
      access_level_2 = FactoryGirl.create(:access_level,
        application_id: app_2.id,
        ad_security_group: "sec_dn_2")
      sec_prof_access_level_2 = FactoryGirl.create(:sec_prof_access_level,
        access_level_id: access_level_2.id,
        security_profile_id: sec_prof.id)

      # Add security profile for termination worker
      emp_trans_1 = FactoryGirl.create(:emp_transaction,
        employee_id: termination.id,
        kind: "Onboarding")
      emp_sec_prof_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans_1.id,
        security_profile_id: sec_prof.id)

      # Add security profile for recent_termination worker
      emp_trans_2 = FactoryGirl.create(:emp_transaction,
        employee_id: recent_termination.id,
        kind: "Onboarding")
      emp_sec_prof_2 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: emp_trans_2.id,
        security_profile_id: sec_prof.id)

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
    let!(:manager_1) { FactoryGirl.create(:employee, employee_id: "12100123", sam_account_name: "samaccountname1", worker_type_id: worker_type.id)}
    let!(:manager_2) { FactoryGirl.create(:employee, employee_id: "12101502", sam_account_name: "samaccountname2", worker_type_id: worker_type.id)}
    let!(:manager_3) { FactoryGirl.create(:employee, employee_id: "12100567", sam_account_name: "samaccountname3", worker_type_id: worker_type.id)}
    let!(:manager_4) { FactoryGirl.create(:employee, employee_id: "12101034", sam_account_name: "samaccountname4", worker_type_id: worker_type.id)}
    let(:job_title_1) { FactoryGirl.create(:job_title, name: "Rich Guy") }
    let(:job_title_2) { FactoryGirl.create(:job_title, name: "Fraud Analyst") }
    let!(:reg_worker_type) { FactoryGirl.create(:worker_type, name: "Regular", kind: "Regular") }
    let!(:temp_worker_type) { FactoryGirl.create(:worker_type, name: "Vendor",kind: "Temporary") }

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
      first_name: "The Big",
      last_name: "Lebowski",
      employee_id: "1234567",
      hire_date: DateTime.new(2005,2,1),
      contract_end_date: nil,
      termination_date: nil,
      worker_type_id: reg_worker_type.id,
      location_id: la.id,
      job_title_id: job_title_1.id,
      manager_id: "12100123",
      department_id: Department.find_by(:name => "BizOpti/Internal System Engineering").id,
      office_phone: nil,
      image_code: nil)

      Employee.create(
      first_name: "Kylie",
      last_name: "Kylie",
      employee_id: "109843",
      hire_date: DateTime.new(2016,4,7),
      contract_end_date: nil,
      termination_date: nil,
      worker_type_id: reg_worker_type.id,
      location_id: melbourne.id,
      job_title_id: job_title_2.id,
      manager_id: "12101034",
      department_id: Department.find_by(:name => "Legal").id,
      office_phone: "(213) 555-1234",
      image_code: nil)

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
        manager: manager_1.dn,
        co: "US",
        accountExpires: "9223372036854775807",
        title: "Rich Guy",
        description: "Rich Guy",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "Los Angeles Office",
        department: "BizOpti/Internal System Engineering",
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
        dn: "cn=Kylie Kylie,ou=Provisional,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
        objectclass: ["top", "person", "organizationalPerson", "user"],
        givenName: "Kylie",
        sn: "Kylie",
        sAMAccountName: "kkylie",
        displayName: "Kylie Kylie",
        userPrincipalName: "kkylie@opentable.com",
        co: "AU",
        accountExpires: "9223372036854775807",
        title: "Fraud Analyst",
        description: "Fraud Analyst",
        employeeType: "Regular",
        physicalDeliveryOfficeName: "Mumbai Office",
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

    # No longer in use
    # Code retained for reference
    xit "should create/update the correct amount of Employees in DB and AD" do
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
          :unicodePwd=>"\"\x00J\x00o\x00e\x00S\x00e\x00v\x00e\x00n\x00P\x00a\x00c\x00k\x00#\x000\x000\x007\x00#\x00\"\x00",
          :workdayUsername=>"jefflebowski",
          :co=>"US",
          :accountExpires=>"9223372036854775807",
          # :title=>"Software Development Team Lead", JOB TITLE can't be generated from xml load since we are getting those from ADP
          # :description=>"Software Development Team Lead",
          :employeeType=>"Regular",
          :physicalDeliveryOfficeName=>"Los Angeles Office",
          :department=>"BizOpti/Internal System Engineering",
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
          :unicodePwd=>"\"\x00J\x00o\x00e\x00S\x00e\x00v\x00e\x00n\x00P\x00a\x00c\x00k\x00#\x000\x000\x007\x00#\x00\"\x00",
          :workdayUsername=>"walters",
          :co=>"GB",
          :accountExpires=>"131118012000000000",
          # :title=>"Contingent Position - Product Management",
          # :description=>"Contingent Position - Product Management",
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
          :unicodePwd=>"\"\x00J\x00o\x00e\x00S\x00e\x00v\x00e\x00n\x00P\x00a\x00c\x00k\x00#\x000\x000\x007\x00#\x00\"\x00",
          :workdayUsername=>"12101234",
          :co=>"US",
          :accountExpires=>"9223372036854775807",
          # :title=>"Account Executive",
          # :description=>"Account Executive",
          :employeeType=>"Regular",
          :physicalDeliveryOfficeName=>"Illinois",
          :department=>"Sales",
          :employeeID=>"12101234",
          :telephoneNumber=>"(213) 555-4321",
          :streetAddress=>"123 East Side, #2310",
          :l=>"Chicago",
          :st=>"Illinois",
          :postalCode=>"60611",
          # :thumbnailPhoto=>Base64.decode64(IMAGE)
          # TODO comment back in when we bring back thumbnail photo
          }})
      expect(@ldap).to receive(:replace_attribute).once.with("cn=The Big Lebowski,ou=Engineering,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :telephoneNumber, "(213) 555-4321")
      expect(@ldap).to receive(:replace_attribute).once.with("cn=Kylie Kylie,ou=Provisional,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com", :accountExpires, "131062374000000000")
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
