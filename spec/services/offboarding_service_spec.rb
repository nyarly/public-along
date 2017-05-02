require 'rails_helper'

describe OffboardingService, type: :service do
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:security_profile) { FactoryGirl.create(:security_profile) }
  let!(:application) { FactoryGirl.create(:application, name: "Google Apps") }
  let!(:access_level) { FactoryGirl.create(:access_level, application_id: application.id) }

  context "with an offboarding emp transaction" do
    let!(:sec_prof_access_level) { FactoryGirl.create(:sec_prof_access_level, security_profile_id: security_profile.id, access_level_id: access_level.id) }
    let!(:emp_transaction) { FactoryGirl.create(:emp_transaction, kind: "Offboarding") }
    let!(:emp_sec_profile) { FactoryGirl.create(:emp_sec_profile, emp_transaction_id: emp_transaction.id, employee_id: employee.id, security_profile_id: security_profile.id)}

    it "should successfully process an offboard" do
      OffboardingService.new([employee])
      expect(emp_transaction.app_transactions[0].application_id).to eq(application.id)
      expect(emp_transaction.app_transactions[0].emp_transaction_id).to eq(emp_transaction.id)
      expect(emp_transaction.app_transactions[0].status).to eq("Pending")
    end
  end

  context "without an offboarding emp transaction" do
    it "should successfully create and process an offboard" do
      OffboardingService.new([employee])
      puts "second emp transaction"
      puts employee.emp_transactions.inspect
      expect(employee.emp_transactions.last.inspect).to eq("hey there")
    end
  end
end
