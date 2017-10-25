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
end
