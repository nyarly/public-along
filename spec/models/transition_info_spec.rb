require 'rails_helper'

RSpec.describe TransitionInfo, type: :model do

  let(:manager) { FactoryGirl.create(:employee,
    first_name: "Alex",
    last_name: "Trebek",
    email: "atrebek@otcorp.com",
    employee_id: 'at123'
  )}

  let(:employee) { FactoryGirl.create(:employee,
    first_name: "Bob",
    last_name: "Barker",
    email: "bbarker@otcorp.com",
    manager_id: manager.employee_id,
    employee_id: 'bb123',
    sam_account_name: 'bbarker'
  )}

  context "offboard with offboarding info" do

    let(:forward_to_employee) { FactoryGirl.create(:employee,
      first_name: "Steven",
      last_name: "Colbert",
      email: "newguy@otcorp.com",
      employee_id: 'sc123'
    )}

    let!(:offboarding_info) { FactoryGirl.create(:offboarding_info,
      archive_data: true,
      employee_id: employee.id,
      forward_email_id: forward_to_employee.id,
      reassign_salesforce_id: forward_to_employee.id,
      transfer_google_docs_id: nil
    )}

    let(:offboard) { FactoryGirl.create(:offboard, employee_id: employee.employee_id) }

    it "should respond to archive data" do
      expect(offboard.archive_data).to eq(true)
    end

    it "should set the forward email to the offboarding info email" do
      expect(offboard.forward_email).to eq('newguy@otcorp.com')
    end

    it "should set should set the google docs transfer email to the manager email" do
      expect(offboard.forward_google).to eq('atrebek@otcorp.com')
    end

    it "should set the reassign salesforce email" do
      expect(offboard.reassign_salesforce).to eq('newguy@otcorp.com')
    end
  end

  context "offboard without offboarding info" do

    let(:offboard) { FactoryGirl.create(:offboard, employee_id: employee.employee_id) }

    it "should respond to archive data" do
      expect(offboard.archive_data).to eq('no info provided')
    end

    it "should set the forward email to the manager's email" do
      expect(offboard.forward_email).to eq('atrebek@otcorp.com')
    end

    it "should set the google docs transfer to the manager's email" do
      expect(offboard.forward_google).to eq('atrebek@otcorp.com')
    end

    it "should set the reassign salesforce email" do
      expect(offboard.reassign_salesforce).to eq('atrebek@otcorp.com')
    end
  end

  context "onboard" do

    let(:buddy) { FactoryGirl.create(:employee) }

    let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
      kind: "Onboarding",
      notes: "welcome!"
    )}

    let!(:onboarding_info) { FactoryGirl.create(:onboarding_info,
      employee_id: employee.id,
      emp_transaction_id: emp_transaction.id,
      buddy_id: buddy.id
    )}

    let(:onboard) { FactoryGirl.create(:onboard, employee_id: employee.employee_id) }

    it "should get onboarding info" do
      expect(onboard.onboarding_info.buddy_id).to eq(buddy.id)
    end

    it "should get the onboarding emp transaction" do
      expect(onboard.emp_transaction.notes).to eq('welcome!')
    end
  end

end
