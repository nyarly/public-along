require 'rails_helper'
require 'rake'

describe "employee rake tasks", type: :tasks do

  let!(:london)      { Location.find_by(name: "London Office") }
  let!(:sf)          { Location.find_by(name: "San Francisco Headquarters") }
  let!(:la)          { Location.find_by(name: "Los Angeles Office") }
  let!(:mumbai)      { Location.find_by(name: "Mumbai Office") }
  let!(:melbourne)   { Location.find_by(name: "Melbourne Office") }
  let!(:illinois)    { Location.find_by(name: "Illinois") }
  let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Regular") }
  let!(:contract_wt) { FactoryGirl.create(:worker_type, kind: "Contractor") }
  let!(:manager)     { FactoryGirl.create(:employee) }

  let(:mailer) { double(ManagerMailer) }

  context "employee:change_status" do

    let(:new_hire_uk) { FactoryGirl.create(:pending_employee,
                         hire_date: Date.new(2016, 7, 29),
                         request_status: "completed") }
    let!(:nh_uk_prof)  { FactoryGirl.create(:profile,
                         employee: new_hire_uk,
                         start_date: Date.new(2016, 7, 29),
                         worker_type: worker_type,
                         location: london) }
    let(:returning_uk) { FactoryGirl.create(:leave_employee,
                         hire_date: Date.new(2016, 1, 1),
                         leave_return_date: Date.new(2016, 7, 29)) }
    let!(:r_uk_prof)    { FactoryGirl.create(:leave_profile,
                         start_date: Date.new(2017, 1, 1),
                         employee: returning_uk,
                         location: london) }
    let(:contract_uk)  { FactoryGirl.create(:pending_employee,
                          hire_date: Date.new(2016, 7, 29),
                          contract_end_date: Date.new(2019, 7, 29),
                          request_status: "completed") }
    let!(:c_uk_prof)    { FactoryGirl.create(:profile,
                          start_date: Date.new(2016, 7, 29),
                          worker_type: contract_wt,
                          employee: contract_uk,
                          location: london) }
    let(:uk_term)      { FactoryGirl.create(:active_employee,
                          termination_date: Date.new(2016, 7, 29)) }
    let!(:uk_term_prof) { FactoryGirl.create(:active_profile,
                          employee: uk_term,
                          location: london) }

    let(:new_hire_us)  { FactoryGirl.create(:pending_employee,
                          hire_date: Date.new(2016, 7, 29),
                          request_status: "completed") }
    let!(:nh_us_prof)   { FactoryGirl.create(:profile,
                          start_date: Date.new(2016, 7, 29),
                          employee: new_hire_us,
                          location: sf) }
    let(:returning_us) { FactoryGirl.create(:leave_employee,
                          hire_date: 1.year.ago,
                          leave_return_date: Date.new(2016, 7, 29)) }
    let!(:r_us_prof)    { FactoryGirl.create(:leave_profile,
                          employee: returning_us,
                          location: sf) }
    let(:rehire)       { FactoryGirl.create(:pending_employee,
                          request_status: "completed",
                          hire_date: Date.new(2016, 1, 1)) }
    let!(:rh_old_prof)  { FactoryGirl.create(:terminated_profile,
                          employee: rehire,
                          start_date: Date.new(2016, 1, 1),
                          end_date: Date.new(2016, 2, 1)) }
    let!(:rh_new_prof)  { FactoryGirl.create(:profile,
                          employee: rehire,
                          start_date: Date.new(2016, 7, 29)) }
    let(:us_term)      { FactoryGirl.create(:active_employee,
                          hire_date: 5.years.ago,
                          termination_date: Date.new(2016, 7, 29)) }
    let!(:t_us_prof)    { FactoryGirl.create(:active_profile,
                          employee: us_term,
                          location: sf) }
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
      # 7/29/2016 at 3am BST/2am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 2, 0, 0, "+00:00"))

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
      expect(new_hire_uk.reload.status).to eq("active")
      expect(returning_uk.reload.status).to eq("active")
      expect(contract_uk.reload.status).to eq("active")
      expect(new_hire_us.reload.status).to eq("pending")
      expect(returning_us.reload.status).to eq("inactive")
    end

    it "should call ldap and update only US new hires and returning leave workers at 3am PST" do

      # 7/29/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 7, 29, 10, 0, 0, "+00:00"))

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
        uk_term.dn, :userAccountControl, "514"
      )
      expect(@ldap).to receive(:replace_attribute).once.with(
        rehire.dn, :userAccountControl, "512"
      )

      allow(@ldap).to receive(:get_operation_result)
      Rake::Task["employee:change_status"].invoke

      expect(new_hire_us.reload.status).to eq("active")
      expect(returning_us.reload.status).to eq("active")
      expect(new_hire_uk.reload.status).to eq("pending")
      expect(returning_uk.reload.status).to eq("inactive")
      expect(uk_term.reload.status).to eq("active")
      expect(rehire.reload.status).to eq("active")
      expect(rh_old_prof.reload.profile_status).to eq("terminated")
      expect(rh_new_prof.reload.profile_status).to eq("active")
    end

    it "should call ldap and update only terminations or workers on leave at 9pm in PST" do
      contract_end_us = FactoryGirl.create(:active_employee,
        first_name: "bb",
        hire_date: 5.years.ago,
        contract_end_date: Date.new(2016, 7, 29),
        manager: manager)
      t_prof = FactoryGirl.create(:active_profile,
        employee: contract_end_us,
        location: sf)

      leave_us = FactoryGirl.create(:active_employee,
        first_name: "cc",
        hire_date: 2.years.ago,
        leave_start_date: Date.new(2016, 7, 30),
        manager: manager)
      t_prof = FactoryGirl.create(:active_profile,
        employee: leave_us,
        location: sf)

      # 7/29/2016 at 9pm PST/3am UTC
      Timecop.freeze(Time.new(2016, 7, 30, 4, 03, 0, "+00:00"))

      allow(@ldap).to receive(:search).and_return([@ldap_entry])
      allow(@ldap_entry).to receive(:dn).and_return("the old dn")

      expect(@ldap).to receive(:replace_attribute).thrice.with(
        "the old dn", :userAccountControl, "514"
      )

      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{us_term.cn}",
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

      expect(OffboardingService).to receive(:new).and_return(@offboarding_service).twice
      expect(@offboarding_service).to receive(:offboard).with([us_term])
      expect(@offboarding_service).to receive(:offboard).with([contract_end_us])
      Rake::Task["employee:change_status"].invoke

      expect(us_term.reload.status).to eq("terminated")
      expect(contract_end_us.reload.status).to eq("terminated")
      expect(leave_us.reload.status).to eq("inactive")
    end


    it "should call ldap and update only terminations, contract ends, or workers on leave at 9pm in IST" do
      contract_end = FactoryGirl.create(:active_employee,
        hire_date: Date.new(2014, 5, 3),
        contract_end_date: Date.new(2016, 7, 29),
        manager: manager)
      ce_profile = FactoryGirl.create(:active_profile,
        employee: contract_end,
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: mumbai.id)
      termination = FactoryGirl.create(:active_employee,
        hire_date: Date.new(2014, 5, 3),
        termination_date: Date.new(2016, 7, 29))
      term_profile = FactoryGirl.create(:active_profile,
        employee: termination,
        department_id: Department.find_by(:name => "Technology/CTO Admin").id,
        location_id: mumbai.id)
      leave = FactoryGirl.create(:active_employee,
        hire_date: Date.new(2014, 5, 3),
        leave_start_date: Date.new(2016, 7, 30))
      leave_profile = FactoryGirl.create(:active_profile,
        employee: leave,
        department_id: Department.find_by(:name => "Infrastructure Engineering").id,
        location_id: mumbai.id)
      new_hire_in = FactoryGirl.create(:active_employee,
        hire_date: Date.new(2016, 7, 29))
      nh_in_profile = FactoryGirl.create(:active_profile,
        employee: new_hire_in,
        department_id: Department.find_by(:name => "Data Analytics & Experimentation").id,
        location_id: mumbai.id)
      new_hire_us = FactoryGirl.create(:active_employee,
        hire_date: Date.new(2016, 7, 29))
      nh_us_profile = FactoryGirl.create(:active_profile,
        employee: new_hire_us,
        location_id: sf.id)
      mailer = double(PeopleAndCultureMailer)

      # 7/29/2016 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      allow(@ldap).to receive(:search).and_return([@ldap_entry])
      allow(@ldap_entry).to receive(:dn).and_return("the old dn")
      expect(@ldap).to receive(:replace_attribute).once.with(
        "the old dn", :userAccountControl, "514"
      )
      expect(@ldap).to receive(:rename).once.with({
        :olddn=>"the old dn",
        :newrdn=>"cn=#{leave.cn}",
        :delete_attributes=>true,
        :new_superior=>"ou=Disabled Users,ou=OT,dc=ottest,dc=opentable,dc=com"})
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

      expect(PeopleAndCultureMailer).to receive(:terminate_contract).with(contract_end).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect(OffboardingService).to receive(:new).and_return(@offboarding_service).twice
      expect(@offboarding_service).to receive(:offboard).with([termination])
      expect(@offboarding_service).to receive(:offboard).with([contract_end])
      Rake::Task["employee:change_status"].invoke

      expect(termination.reload.status).to eq("terminated")
      expect(contract_end.reload.status).to eq("terminated")
      expect(leave.reload.status).to eq("inactive")
    end

    it "should offboard deactivated employee group at 9pm in IST" do
      ind_term = FactoryGirl.create(:active_employee,
        termination_date: Date.new(2016, 7, 29))
      ind_term_prof = FactoryGirl.create(:active_profile,
        employee: ind_term,
        location: mumbai,
        department: Department.find_by(:name => "Technology/CTO Admin"))

      # 7/29/ 2017 at 9pm IST/3:30pm UTC
      Timecop.freeze(Time.new(2016, 7, 29, 15, 30, 0, "+00:00"))

      expect(OffboardingService).to receive(:new).and_return(@offboarding_service).once
      ad = double(ActiveDirectoryService)
      allow(ActiveDirectoryService).to receive(:new).and_return(ad)
      allow(ad).to receive(:deactivate)
      allow(ad).to receive(:activate)
      allow(ad).to receive(:terminate)
      expect(@offboarding_service).to receive(:offboard).once.with([ind_term])

      Rake::Task["employee:change_status"].invoke

      expect(ind_term.reload.status).to eq("terminated")
      expect(ind_term_prof.reload.profile_status).to eq("terminated")
    end

    it "should send tech table offboard instructions at noon on the termination day in IST" do
      manager = FactoryGirl.create(:regular_employee)

      termination = FactoryGirl.create(:active_employee,
        manager: manager,
        termination_date: Date.new(2016, 7, 29))
      profile = FactoryGirl.create(:active_profile,
        employee: termination,
        location: mumbai,
        department: Department.find_by(:name => "Technology/CTO Admin"))

        Timecop.freeze(Time.new(2016, 7, 29, 6, 30, 0, "+00:00"))

        expect(TechTableMailer).to receive_message_chain(:offboard_instructions, :deliver_now)
        Rake::Task["employee:change_status"].invoke
    end

    it "should remove worker from all security groups at 3am, 7 days after termination" do
      manager = FactoryGirl.create(:regular_employee)
      termination = FactoryGirl.create(:active_employee,
        manager_id: manager,
        hire_date: Date.new(2014, 5, 3),
        termination_date: Date.new(2016, 8, 21))
      profile = FactoryGirl.create(:active_profile,
        employee: termination,
        department: Department.find_by(:name => "Technology/CTO Admin"),
        location: sf)
      recent_termination = FactoryGirl.create(:terminated_employee,
        manager: manager,
        hire_date: Date.new(2014, 5, 3),
        termination_date: Date.new(2016, 8, 20))
      profile = FactoryGirl.create(:terminated_profile,
        employee: recent_termination,
        department: Department.find_by(:name => "Technology/CTO Admin"),
        location: sf)

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
      ldap_success = OpenStruct.new(code: 0, message: "message")

      # 8/28/2016 at 3am PST/10am UTC
      Timecop.freeze(Time.new(2016, 8, 28, 10, 0, 0, "+00:00"))
      allow(@ldap).to receive(:get_operation_result).and_return(ldap_success)

      expect(@ldap).to receive(:modify).once.ordered.with({:dn => "sec_dn_1", :operations => [[:delete, :member, termination.dn]]})
      expect(@ldap).to receive(:modify).once.ordered.with({:dn => "sec_dn_2", :operations => [[:delete, :member, termination.dn]]})
      expect(@ldap).to_not receive(:modify).with({:dn => "sec_dn_1", :operations => [[:delete, :member, recent_termination.dn]]})
      expect(@ldap).to_not receive(:modify).with({:dn => "sec_dn_2", :operations => [[:delete, :member, recent_termination.dn]]})

      Rake::Task["employee:change_status"].invoke
    end
  end

  context "employee:send_onboarding_reminders" do
    let!(:reg_wt)     { FactoryGirl.create(:worker_type, code: "FTR") }
    let!(:us_due_tom) { FactoryGirl.create(:pending_employee,
                        request_status: "completed",
                        hire_date: Date.new(2017, 12, 4)) }
    let!(:us_dt_prof) { FactoryGirl.create(:profile,
                        start_date: Date.new(2017, 12, 4),
                        employee: us_due_tom) }
    let!(:us_overdue) { FactoryGirl.create(:pending_employee,
                        request_status: "waiting",
                        hire_date: Date.new(2017, 12, 4)) }
    let!(:us_od_prof) { FactoryGirl.create(:profile,
                        employee: us_overdue,
                        start_date: Date.new(2017, 12, 4)) }

    let!(:au_due_tom) { FactoryGirl.create(:pending_employee,
                        request_status: "waiting",
                        hire_date: Date.new(2017, 12, 11)) }
    let!(:au_profile) { FactoryGirl.create(:profile,
                        start_date: Date.new(2017, 12, 11),
                        employee: au_due_tom,
                        location: Location.find_by_name("Melbourne Office")) }

    let!(:json)       { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
    let!(:nh_evt)     { FactoryGirl.create(:adp_event,
                        status: "new",
                        json: json,
                        kind: "worker.hire") }

    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/employee", [Rails.root.to_s], ''
      Rake::Task.define_task :environment
    end

    after :each do
      Timecop.return
    end

    it "should remind manager to onboard us worker" do
      # 9am PST
      Timecop.freeze(Time.new(2017, 11, 26, 17, 0, 0, "+00:00"))
      expect(ReminderWorker).to receive(:perform_async).with({:employee_id=>us_overdue.id})
      Rake::Task["employee:send_onboarding_reminders"].invoke
    end

    it "should remind manager to onboard au worker" do
      # 9am AEST
      Timecop.freeze(Time.new(2017, 11, 25, 22, 00, 0, "+00:00"))
      expect(ReminderWorker).to receive(:perform_async).with({:employee_id=>au_due_tom.id})
      Rake::Task["employee:send_onboarding_reminders"].invoke
    end

    it "should remind manager to onboard rehire" do
      Timecop.freeze(Time.new(2018, 8, 23, 16, 0, 0, "+00:00"))
     expect(ReminderWorker).to receive(:perform_async).with({:event_id=>nh_evt. id})
     Rake::Task["employee:send_onboarding_reminders"].invoke
    end
  end


  context "employee:send_contract_end_notifications" do
    let!(:manager)    { FactoryGirl.create(:employee) }
    let!(:contractor) { FactoryGirl.create(:contract_worker,
                        status: "active",
                        request_status: "none",
                        contract_end_date: Date.new(2017, 12, 01),
                        termination_date: nil,
                        manager: manager) }
    let!(:cont_2)     { FactoryGirl.create(:contract_worker,
                        status: "active",
                        contract_end_date: Date.new(2017, 11, 11),
                        termination_date: Date.new(2017, 12, 01),
                        manager: manager)}

    before :each do
      Rake.application = Rake::Application.new
      Rake.application.rake_require "lib/tasks/employee", [Rails.root.to_s], ''
      Rake::Task.define_task :environment
    end

    after :each do
      Timecop.return
    end

    it "should remind manager of worker with contract end date in two weeks" do
      Timecop.freeze(Time.new(2017, 11, 17, 17, 0, 0, "+00:00"))
      expect(ContractorWorker).to receive(:perform_async).with(contractor.id)
      Rake::Task["employee:send_contract_end_notifications"].invoke
      expect(contractor.reload.request_status).to eq("waiting")
    end
  end
end
