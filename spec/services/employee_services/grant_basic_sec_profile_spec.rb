require 'rails_helper'

describe EmployeeService::GrantBasicSecProfile, type: :sevice do
  let!(:regular)  { FactoryGirl.create(:security_profile, name: "Basic Regular Worker Profile") }
  let!(:temp)     { FactoryGirl.create(:security_profile, name: "Basic Temp Worker Profile") }
  let!(:contract) { FactoryGirl.create(:security_profile, name: "Basic Contract Worker Profile") }

  context "with a regular worker" do
    let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Regular") }
    let(:employee)     { FactoryGirl.create(:pending_employee) }
    let!(:profile)     { FactoryGirl.create(:profile,
                         employee: employee,
                         worker_type: worker_type) }

    it "should add the regular security profile" do
      service = EmployeeService::GrantBasicSecProfile.new(employee).process!
      expect(service).to include(regular)
      expect(service).not_to include(temp)
      expect(service).not_to include(contract)
      expect(employee.security_profiles).to eq([regular])
    end
  end

  context "with a temp worker" do
    let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Temporary") }
    let(:employee)     { FactoryGirl.create(:pending_employee) }
    let!(:profile)     { FactoryGirl.create(:profile,
                         employee: employee,
                         worker_type: worker_type) }

    it "should add the temporary security profile" do
      service = EmployeeService::GrantBasicSecProfile.new(employee).process!
      expect(service).to include(temp)
      expect(service).not_to include(regular)
      expect(service).not_to include(contract)
      expect(employee.security_profiles).to eq([temp])
    end
  end

  context "with a contract worker" do
    let!(:worker_type) { FactoryGirl.create(:worker_type, kind: "Contractor") }
    let(:employee)     { FactoryGirl.create(:pending_employee) }
    let!(:profile)     { FactoryGirl.create(:profile,
                         employee: employee,
                         worker_type: worker_type) }

    it "should add the temporary security profile" do
      service = EmployeeService::GrantBasicSecProfile.new(employee).process!
      expect(service).to include(contract)
      expect(service).not_to include(regular)
      expect(service).not_to include(temp)
      expect(employee.security_profiles).to eq([contract])
    end
  end

  context "with a rehire" do
    let(:old_wt)        { FactoryGirl.create(:worker_type,
                          kind: "Regular") }
    let(:new_wt)        { FactoryGirl.create(:worker_type,
                          kind: "Contractor") }
    let(:rehire)        { FactoryGirl.create(:employee,
                          status: "pending") }
    let!(:old_position) { FactoryGirl.create(:profile,
                          employee: rehire,
                          profile_status: "terminated",
                          worker_type: old_wt,
                          management_position: false) }
    let!(:new_position) { FactoryGirl.create(:profile,
                          employee: rehire,
                          profile_status: "pending",
                          worker_type: new_wt,
                          management_position: true) }

    it "should give basic security profile for new worker type" do
      service = EmployeeService::GrantBasicSecProfile.new(rehire).process!
      expect(service).to include(contract)
      expect(service).not_to include(regular)
      expect(service).not_to include(temp)
      expect(rehire.security_profiles).to eq([contract])
    end
  end
end
