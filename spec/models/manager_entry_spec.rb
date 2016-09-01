require 'rails_helper'

RSpec.describe ManagerEntry do
  let(:sas) { double(SecAccessService) }

  before :each do
    allow(SecAccessService).to receive(:new).and_return(sas)
    allow(sas).to receive(:apply_ad_permissions)
  end

  context "New Hire" do
    let(:params) do
      {
        kind: "Onboarding",
        user_id: 12,
        buddy_id: 123,
        cw_email: 1,
        cw_google_membership: 0,
        notes: "These notes",
        employee_id: employee.id,
        security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
        machine_bundle_id: machine_bundle.id
      }
    end

    let(:manager_entry) { ManagerEntry.new(params) }
    let(:employee) { FactoryGirl.create(:employee) }
    let(:sp_1) { FactoryGirl.create(:security_profile) }
    let(:sp_2) { FactoryGirl.create(:security_profile) }
    let(:sp_3) { FactoryGirl.create(:security_profile) }
    let(:machine_bundle) { FactoryGirl.create(:machine_bundle) }

    it "should create an emp_transaction with the right attrs" do
      expect(manager_entry.emp_transaction.kind).to eq("Onboarding")
      expect(manager_entry.emp_transaction.user_id).to eq(12)
      expect(manager_entry.emp_transaction.buddy_id).to eq(123)
      expect(manager_entry.emp_transaction.cw_email).to eq(true)
      expect(manager_entry.emp_transaction.cw_google_membership).to eq(false)
      expect(manager_entry.emp_transaction.notes).to eq("These notes")
    end

    it "should create security profiles" do
      manager_entry.save

      expect(manager_entry.emp_transaction.security_profiles.count).to eq(3)
      expect(manager_entry.emp_transaction.emp_sec_profiles.first.employee_id).to eq(employee.id)
    end

    it "should build machine bundles" do
      manager_entry.save

      expect(manager_entry.emp_transaction.machine_bundles.count).to eq(1)
      expect(manager_entry.emp_transaction.emp_mach_bundles.first.employee_id).to eq(employee.id)
    end

    it "should report errors" do
      params[:employee_id] = nil

      manager_entry.save

      expect(manager_entry.errors.messages).to eq({:"emp_sec_profiles.employee_id"=>["can't be blank"], :emp_mach_bundles=>["is invalid"]})
    end
  end

  context "Security Access Change" do
    let(:params) do
      {
        kind: "Security Access",
        user_id: 12,
        buddy_id: 123,
        employee_id: employee.id,
        security_profile_ids: [sp_2.id, sp_3.id, sp_4.id]
      }
    end

    let(:manager_entry) { ManagerEntry.new(params) }
    let!(:employee) { FactoryGirl.create(:employee) }
    let(:sp_1) { FactoryGirl.create(:security_profile) }
    let(:sp_2) { FactoryGirl.create(:security_profile) }
    let(:sp_3) { FactoryGirl.create(:security_profile) }
    let(:sp_4) { FactoryGirl.create(:security_profile) }

    it "should succeed" do
    end

    it "should add and revoke specified security profiles" do
      esp_1 = FactoryGirl.create(:emp_sec_profile, employee_id: employee.id, security_profile_id: sp_1.id, revoke_date: nil)
      esp_2 = FactoryGirl.create(:emp_sec_profile, employee_id: employee.id, security_profile_id: sp_2.id, revoke_date: nil)
      esp_3 = FactoryGirl.create(:emp_sec_profile, employee_id: employee.id, security_profile_id: sp_3.id, revoke_date: nil)

      manager_entry.save

      expect(employee.reload.security_profiles.map(&:id)).to eq([sp_1.id, sp_2.id, sp_3.id, sp_4.id])
      expect(esp_1.reload.revoke_date).to eq(Date.today)
      expect(esp_2.reload.revoke_date).to eq(nil)
      expect(esp_3.reload.revoke_date).to eq(nil)
    end

    it "should not include buddy or machine bundles" do
    end
   end

  context "Re-hire" do
  end
end
