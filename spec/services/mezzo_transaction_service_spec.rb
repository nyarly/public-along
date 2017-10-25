require 'rails_helper'

describe MezzoTransactionService, type: :service do
  let!(:employee)         { FactoryGirl.create(:employee) }
  let!(:security_profile) { FactoryGirl.create(:security_profile) }

  context "#process! adds a security profile" do
    it "should create an emp transaction and emp sec profile for security profile" do
      MezzoTransactionService.new(employee.id, security_profile.id).process!
      expect(employee.emp_transactions.count).to eq(1)
      expect(employee.emp_transactions.last.kind).to eq("Service")
      expect(employee.emp_transactions.last.emp_sec_profiles.count).to eq(1)
      expect(employee.emp_transactions.last.emp_sec_profiles.last.security_profile_id).to eq(security_profile.id)
      expect(employee.security_profiles).to eq([security_profile])
    end
  end
end
