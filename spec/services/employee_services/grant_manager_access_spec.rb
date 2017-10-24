require 'rails_helper'

describe EmployeeService::GrantManagerAccess, type: :service do
  let!(:manager_sec_profile) { FactoryGirl.create(:security_profile, name: "Basic Manager") }

  context "worker should not be given manager access" do
    let(:employee) { FactoryGirl.create(:employee, status: "active") }
    let!(:profile) { FactoryGirl.create(:profile,
                     profile_status: "active",
                     employee: employee,
                     management_position: false) }

    it "should not not change security access" do
      expect{
        EmployeeService::GrantManagerAccess.new(employee).process!
      }.not_to change{employee.security_profiles}
      expect(employee.security_profiles).to eq([])
    end
  end

  context "worker should be given manager access" do
    let(:employee) { FactoryGirl.create(:employee, status: "active") }
    let!(:profile) { FactoryGirl.create(:profile,
                     profile_status: "active",
                     employee: employee,
                     management_position: true) }

    it "should add basic manager security profile to employee" do
      EmployeeService::GrantManagerAccess.new(employee).process!
      expect(employee.reload.security_profiles).to eq([manager_sec_profile])
      expect(employee.emp_transactions.last.kind).to eq("Service")
    end
  end
end
