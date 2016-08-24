require 'rails_helper'

RSpec.describe ManagerEntry do
  let(:params) do
    {
      kind: "Onboarding",
      user_id: 12,
      buddy_id: 123,
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
