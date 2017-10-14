require 'rails_helper'

RSpec.describe ManagerEntry do
  let(:sas) { double(SecAccessService) }
  let!(:manager_sec_prof) { FactoryGirl.create(:security_profile, name: "Basic Manager") }

  before :each do
    allow(SecAccessService).to receive(:new).and_return(sas)
    allow(sas).to receive(:apply_ad_permissions)
  end

  context "Onboarding New Hire" do
    let(:user) { FactoryGirl.create(:user) }
    let(:buddy) { FactoryGirl.create(:active_employee) }
    let(:employee) { FactoryGirl.create(:pending_employee, request_status: "waiting") }
    let(:sp_1) { FactoryGirl.create(:security_profile) }
    let(:sp_2) { FactoryGirl.create(:security_profile) }
    let(:sp_3) { FactoryGirl.create(:security_profile) }
    let(:machine_bundle) { FactoryGirl.create(:machine_bundle) }

    let(:params) do
      {
        kind: "Onboarding",
        user_id: user.id,
        buddy_id: buddy.id,
        cw_email: 1,
        cw_google_membership: 0,
        notes: "These notes",
        employee_id: employee.id,
        security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
        machine_bundle_id: machine_bundle.id
      }
    end

    it "should create an emp_transaction with the right attrs" do
      manager_entry = ManagerEntry.new(params)
      expect(manager_entry.emp_transaction.kind).to eq("Onboarding")
      expect(manager_entry.emp_transaction.user_id).to eq(user.id)
      expect(manager_entry.emp_transaction.notes).to eq("These notes")
      expect(manager_entry.emp_transaction.employee_id).to eq(employee.id)
    end

    it "should create onboarding info" do
      manager_entry = ManagerEntry.new(params)
      manager_entry.save

      expect(manager_entry.emp_transaction.onboarding_infos.count).to eq(1)
      expect(manager_entry.emp_transaction.onboarding_infos.first.buddy_id).to eq(buddy.id)
      expect(manager_entry.emp_transaction.onboarding_infos.first.cw_email).to eq(true)
      expect(manager_entry.emp_transaction.onboarding_infos.first.cw_google_membership).to eq(false)
    end

    it "should create security profiles" do
      manager_entry = ManagerEntry.new(params)
      manager_entry.save

      expect(manager_entry.emp_transaction.security_profiles.count).to eq(3)
      expect(manager_entry.emp_transaction.emp_sec_profiles.first.security_profile_id).to eq(sp_1.id)
    end

    it "should build machine bundles" do
      manager_entry = ManagerEntry.new(params)
      manager_entry.save

      expect(manager_entry.emp_transaction.machine_bundles.count).to eq(1)
      expect(manager_entry.emp_transaction.employee_id).to eq(employee.id)
      expect(employee.emp_mach_bundles.count).to eq(1)
      expect(employee.emp_mach_bundles[0].machine_bundle).to eq(machine_bundle)
    end

    it "should report errors" do
      params[:employee_id] = nil
      params[:event_id] = nil
      manager_entry = ManagerEntry.new(params)

      manager_entry.save

      expect(manager_entry.errors.messages).to eq({:base => ["Employee can not be blank. Please revisit email link to refresh page."]})
    end
  end

  context "Onboarding Job Change with Linked Accounts" do
    let(:manager) { FactoryGirl.create(:employee) }
    let!(:manager_profile) { FactoryGirl.create(:profile,
      employee: manager,
      adp_employee_id: "101836") }
    let!(:worker_type) { FactoryGirl.create(:worker_type,
      code: "ACW",
      name: "Contractor")}
    let(:old_employee) { FactoryGirl.create(:terminated_employee) }
    let(:user) { FactoryGirl.create(:user) }
    let(:hire_event) { File.read(Rails.root.to_s+"/spec/fixtures/adp_cat_change_hire_event.json") }
    let(:event) { FactoryGirl.create(:adp_event,
      status: "New",
      json: hire_event) }
    let(:sp_1) { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
    let(:sp_2) { FactoryGirl.create(:security_profile, name: "Basic Temp Worker Profile") }
    let(:sp_3) { FactoryGirl.create(:security_profile, name: "Basic Contract Worker Profile") }
    let(:machine_bundle) { FactoryGirl.create(:machine_bundle) }
    let(:link_on_params) do
      {
        kind: "Onboarding",
        event_id: event.id,
        user_id: user.id,
        buddy_id: nil,
        cw_email: 1,
        cw_google_membership: 0,
        notes: "These notes",
        security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
        machine_bundle_id: machine_bundle.id,
        link_email: "on",
        linked_account_id: old_employee.id
      }
    end
    let(:link_off_params) do
      {
        kind: "Onboarding",
        event_id: event.id,
        user_id: user.id,
        buddy_id: nil,
        cw_email: 1,
        cw_google_membership: 0,
        notes: "These notes",
        security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
        machine_bundle_id: machine_bundle.id,
        link_email: "off"
      }
    end
    let(:ads) { double(ActiveDirectoryService) }
    let(:profiler) { EmployeeProfile.new }

    it "should create a new profile on employee when manager links employees" do
      manager_entry = ManagerEntry.new(link_on_params)

      expect{
        manager_entry.save
      }.not_to change{Employee.count}
      expect(Employee.find_by(last_name: "LN_FAKE_JP").profiles.count).to eq(2)
      expect(manager_entry.emp_transaction.employee).to eq(old_employee)

      old_employee.reload
      event.reload

      expect(old_employee.status).to eq("pending")
      expect(old_employee.worker_type).to eq(worker_type)
      expect(old_employee.machine_bundles.first).to eq(machine_bundle)
      expect(old_employee.profiles.count).to eq(2)
      expect(old_employee.profiles.terminated.count).to eq(1)
      expect(old_employee.profiles.pending.last.worker_type).to eq(worker_type)
      expect(event.status).to eq("Processed")
    end

    it "should create a new employee when the manager does not link accounts" do
      job_title = FactoryGirl.create(:job_title,
        code: "CTRANL",
        name: "Control Analyst")

      manager_entry = ManagerEntry.new(link_off_params)
      manager_entry.save

      employee = Employee.find_by(last_name: "LN_FAKE_JP")
      event.reload

      expect(employee.status).to eq("pending")
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.machine_bundles.first).to eq(machine_bundle)
      expect(employee.profiles.count).to eq(1)
      expect(employee.profiles.terminated.last).to eq(nil)
      expect(employee.profiles.pending.last.worker_type).to eq(worker_type)
      expect(event.status).to eq("Processed")
    end
  end

  context "Onboard Rehire with Linked Accounts" do
    let(:manager) { FactoryGirl.create(:employee) }
    let!(:manager_profile) { FactoryGirl.create(:profile,
      employee: manager,
      adp_employee_id: "654321") }
    let!(:worker_type) { FactoryGirl.create(:worker_type,
      code: "FTR",
      name: "Regular Full-Time")}
    let(:old_employee) { FactoryGirl.create(:terminated_employee) }
    let(:user) { FactoryGirl.create(:user) }
    let(:rehire_event) { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
    let(:event) { FactoryGirl.create(:adp_event,
      status: "New",
      json: rehire_event) }
    let(:sp_1) { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
    let(:sp_2) { FactoryGirl.create(:security_profile, name: "Basic Temp Worker Profile") }
    let(:sp_3) { FactoryGirl.create(:security_profile, name: "Basic Contract Worker Profile") }
    let(:machine_bundle) { FactoryGirl.create(:machine_bundle) }
    let(:link_on_params) do
      {
        kind: "Onboarding",
        event_id: event.id,
        user_id: user.id,
        buddy_id: nil,
        cw_email: 1,
        cw_google_membership: 0,
        notes: "These notes",
        security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
        machine_bundle_id: machine_bundle.id,
        link_email: "on",
        linked_account_id: old_employee.id
      }
      end
    let(:link_off_params) do
      {
        kind: "Onboarding",
        event_id: event.id,
        user_id: user.id,
        buddy_id: nil,
        cw_email: 1,
        cw_google_membership: 0,
        notes: "These notes",
        security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
        machine_bundle_id: machine_bundle.id,
        link_email: "off"
      }
    end
    let(:ads) { double(ActiveDirectoryService) }
    let(:profiler) { EmployeeProfile.new }

    it "should create a new profile on employee when manager links employees" do
      manager_entry = ManagerEntry.new(link_on_params)

      expect{
        manager_entry.save
      }.not_to change{Employee.count}
      expect(Employee.find_by(last_name: "Fakename").profiles.count).to eq(2)
      expect(manager_entry.emp_transaction.employee).to eq(old_employee)

      old_employee.reload
      event.reload

      expect(old_employee.status).to eq("pending")
      expect(old_employee.worker_type).to eq(worker_type)
      expect(old_employee.machine_bundles.first).to eq(machine_bundle)
      expect(old_employee.profiles.count).to eq(2)
      expect(old_employee.profiles.terminated.count).to eq(1)
      expect(old_employee.profiles.pending.last.worker_type).to eq(worker_type)
      expect(old_employee.profiles.pending.last.start_date).to eq(DateTime.new(2018, 9, 1))
      expect(event.status).to eq("Processed")
    end

    it "should create a new employee when the manager doesn't link employees" do
      manager_entry = ManagerEntry.new(link_off_params)
      manager_entry.save

      employee = Employee.find_by(last_name: "Fakename")
      event.reload

      expect(employee.status).to eq("pending")
      expect(employee.worker_type).to eq(worker_type)
      expect(employee.machine_bundles.first).to eq(machine_bundle)
      expect(employee.profiles.count).to eq(1)
      expect(employee.profiles.terminated.last).to eq(nil)
      expect(employee.profiles.pending.last.worker_type).to eq(worker_type)
      expect(employee.profiles.pending.last.job_title.name).to eq("Specialist - Major Accounts - Sr.")
      expect(event.status).to eq("Processed")
    end
  end

  context "Security Access Change" do
    let(:params) do
      {
        kind: "Security Access",
        user_id: user.id,
        employee_id: employee.id,
        security_profile_ids: [sp_1.id, sp_3.id, sp_4.id]
      }
    end
    let(:user) { FactoryGirl.create(:user) }
    let(:manager_entry) { ManagerEntry.new(params) }
    let(:employee) { FactoryGirl.create(:active_employee) }
    let(:sp_1) { FactoryGirl.create(:security_profile) }
    let(:sp_2) { FactoryGirl.create(:security_profile) }
    let(:sp_3) { FactoryGirl.create(:security_profile) }
    let(:sp_4) { FactoryGirl.create(:security_profile) }

    it "should add and revoke specified security profiles" do
      et_1 = FactoryGirl.create(:emp_transaction, employee_id: employee.id)
      esp_1 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: et_1.id,
        security_profile_id: sp_1.id,
        revoking_transaction_id: nil)
      esp_2 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: et_1.id,
        security_profile_id: sp_2.id,
        revoking_transaction_id: nil)
      esp_3 = FactoryGirl.create(:emp_sec_profile,
        emp_transaction_id: et_1.id,
        security_profile_id: sp_3.id,
        revoking_transaction_id: nil)

      manager_entry.save

      expect(employee.reload.security_profiles.pluck(:id).sort).to eq([sp_1.id, sp_2.id, sp_3.id, sp_4.id])
      expect(employee.reload.active_security_profiles.pluck(:id).sort).to eq([sp_1.id, sp_3.id, sp_4.id])
      expect(employee.reload.revoked_security_profiles.pluck(:id).sort).to eq([sp_2.id])
      expect(esp_1.reload.revoking_transaction_id).to be_nil
      expect(esp_2.reload.revoking_transaction_id).to_not be_nil
      expect(esp_3.reload.revoking_transaction_id).to be_nil
    end
   end

   context "Offboarding" do
    let(:params) do
      {
        kind: "Offboarding",
        user_id: user.id,
        employee_id: employee.id,
        archive_data: true,
        replacement_hired: false,
        forward_email_id: forward.id,
        reassign_salesforce_id: forward.id,
        transfer_google_docs_id: forward.id,
        notes: "stuff"
      }
    end

    let(:user) { FactoryGirl.create(:user) }
    let(:forward) { FactoryGirl.create(:employee) }
    let(:manager_entry) { ManagerEntry.new(params) }
    let!(:employee) { FactoryGirl.create(:active_employee) }
    let!(:security_profile) { FactoryGirl.create(:security_profile) }
    let!(:emp_sec_profile) { FactoryGirl.create(:emp_sec_profile, security_profile_id: security_profile.id) }

    it "should create offboarding info" do
      manager_entry.save

      expect(manager_entry.emp_transaction.offboarding_infos.count).to eq(1)
      expect(manager_entry.emp_transaction.offboarding_infos.first.archive_data).to eq(true)
      expect(manager_entry.emp_transaction.offboarding_infos.first.replacement_hired).to eq(false)
      expect(manager_entry.emp_transaction.offboarding_infos.first.forward_email_id).to eq(forward.id)
      expect(manager_entry.emp_transaction.offboarding_infos.first.reassign_salesforce_id).to eq(forward.id)
      expect(manager_entry.emp_transaction.offboarding_infos.first.transfer_google_docs_id).to eq(forward.id)
      expect(manager_entry.emp_transaction.notes).to eq("stuff")

    end
  end

  context "Equipment" do
    let(:params) do
      {
        kind: "Equipment",
        user_id: user.id,
        employee_id: employee.id,
        machine_bundle_id: machine_bundle.id
      }
    end

    let(:employee) { FactoryGirl.create(:active_employee) }
    let(:user) { FactoryGirl.create(:user) }
    let(:machine_bundle) { FactoryGirl.create(:machine_bundle) }
    let(:manager_entry) { ManagerEntry.new(params) }

    it "should create equipment request info" do
      manager_entry.save

      expect(manager_entry.emp_transaction.emp_mach_bundles.first.machine_bundle).to eq(machine_bundle)
    end
  end
end
