require 'rails_helper'

RSpec.describe OffboardCommand, type: :model do

  let!(:manager) { FactoryGirl.create(:employee,
    first_name: "Alex",
    last_name: "Trebek",
    email: "atrebek@otcorp.com",
    employee_id: 'at123'
  )}

  let!(:employee) { FactoryGirl.create(:employee,
    first_name: "Bob",
    last_name: "Barker",
    email: "bbarker@otcorp.com",
    manager_id: manager.employee_id,
    employee_id: 'bb123'
  )}

  let!(:forward_to_employee) { FactoryGirl.create(:employee,
    first_name: "Steven",
    last_name: "Colbert",
    email: "newguy@otcorp.com",
    employee_id: 'sc123'
  )}

  let!(:offboard_command) {FactoryGirl.build(:offboard_command, employee_id: employee.employee_id)}

  context "with offboarding info" do

    let!(:offboarding_info) { FactoryGirl.create(:offboarding_info,
      employee_id: employee.id,
      forward_email_id: forward_to_employee.id,
      reassign_salesforce_id: forward_to_employee.id,
      transfer_google_docs_id: nil
    )}

    it "should meet validations" do
      expect(offboard_command).to_not allow_value(nil).for(:employee_id)
    end

    it "should make an ot_id" do
      expect(offboard_command.ot_id).to eq('bbarker')
    end

    it "should get an employee email" do
      expect(offboard_command.employee_email).to eq('bbarker@otcorp.com')
    end

    it "should get an employee name" do
      expect(offboard_command.employee_name).to eq('Bob Barker')
    end

    it "should set the forward email to the offboarding info email" do
      expect(offboard_command.forward_email).to eq('newguy@otcorp.com')
    end

    it "should set should set the google docs transfer email to the manager email" do
      expect(offboard_command.forward_google).to eq('atrebek@otcorp.com')
    end
  end

  context "with offboarding info and with google forwarding id" do

    let!(:offboarding_info) { FactoryGirl.create(:offboarding_info,
      employee_id: employee.id,
      forward_email_id: forward_to_employee.id,
      reassign_salesforce_id: forward_to_employee.id,
      transfer_google_docs_id: forward_to_employee.id
    )}

    it "should use the google docs transfer email" do
      expect(offboard_command.forward_google).to eq('newguy@otcorp.com')
    end
  end

  context "without offboarding info" do

    it "should meet validations" do
      expect(offboard_command).to_not allow_value(nil).for(:employee_id)
    end

    it "should make an ot_id" do
      expect(offboard_command.ot_id).to eq('bbarker')
    end

    it "should get an employee email" do
      expect(offboard_command.employee_email).to eq('bbarker@otcorp.com')
    end

    it "should get an employee name" do
      expect(offboard_command.employee_name).to eq('Bob Barker')
    end

    it "should set the forward email to the manager's email" do
      expect(offboard_command.forward_email).to eq('atrebek@otcorp.com')
    end

    it "should set the google docs transfer to the manager's email" do
      expect(offboard_command.forward_google).to eq('atrebek@otcorp.com')
    end
  end

end
