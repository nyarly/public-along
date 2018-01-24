require 'rails_helper'

describe EmployeePolicy, type: :policy do
  context "is conversion" do
    let(:contractor)  { FactoryGirl.create(:employee,
                        status: "active",
                        contract_end_date: nil,
                        termination_date: nil) }
    let!(:prof_1)     { FactoryGirl.create(:profile,
                        profile_status: "active",
                        employee: contractor) }
    let!(:prof_2)     { FactoryGirl.create(:profile,
                        profile_status: "pending",
                        employee: contractor) }
    let(:employee)    { FactoryGirl.create(:employee,
                        status: "active") }
    let!(:prof_3)     { FactoryGirl.create(:profile,
                        profile_status: "active",
                        employee: employee) }

    it "returns true when true" do
      policy = EmployeePolicy.new(contractor)
      expect(policy.is_conversion?).to eq(true)
    end

    it "returns false when false" do
      policy = EmployeePolicy.new(employee)
      expect(policy.is_conversion?).to eq(false)
    end
  end
end
