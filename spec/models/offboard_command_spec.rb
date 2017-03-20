require 'rails_helper'

RSpec.describe OffboardCommand, type: :model do

  context "with offboarding info" do
    let!(:manager) { FactoryGirl.create(:employee,
      first_name: "Alex",
      last_name: "Trebek",
      email: "atrebek@otcorp.com"
    )}

    let!(:employee) { FactoryGirl.create(:employee,
      first_name: "Bob",
      last_name: "Barker",
      email: "bbarker@otcorp.com",
      manager_id: manager.employee_id
    )}

    let!(:forward_to_employee) { FactoryGirl.create(:employee,
      first_name: "Steven",
      last_name: "Colbert",
      email: "newguy@otcorp.com"
    )}

    let!(:offboarding_info) { FactoryGirl.create(:offboarding_info,
      employee_id: employee.id,
      forward_email_id: forward_to_employee.id,
      reassign_salesforce_id: forward_to_employee.id
    )}

    it "should meet validations" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command).to be_valid
      expect(offboard_command).to_not allow_value(nil).for(:employee_id)
    end

    it "should find the employee" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.employee.id).to eq(offboard_command.employee_id)
    end

    it "should make an ot_id" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.ot_id).to eq('bbarker')
    end

    it "should set the forward email to the offboarding info email" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.forward_email).to eq('newguy@otcorp.com')
    end

    it "should have offboarding info" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.employee.offboarding_infos.count).to eq(1)
    end
  end

  context "without offboarding info" do
    let!(:manager) { FactoryGirl.create(:employee,
      first_name: "Alex",
      last_name: "Trebek",
      email: "atrebek@otcorp.com"
    )}

    let!(:employee) { FactoryGirl.create(:employee,
      first_name: "Bob",
      last_name: "Barker",
      email: "bbarker@otcorp.com",
      manager_id: manager.id
    )}

    it "should meet validations" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command).to be_valid
      expect(offboard_command).to_not allow_value(nil).for(:employee_id)
    end

    it "should find the employee" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.employee.id).to eq(offboard_command.employee_id)
    end

    it "should make an ot_id" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.ot_id).to eq('bbarker')
    end

    it "should set the forward email to the manager's email" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      offboard_command.employee
      expect(offboard_command.forward_email).to eq('atrebek@otcorp.com')
    end

    it "should not have offboarding info" do
      offboard_command = FactoryGirl.build(:offboard_command, employee_id: employee.id)
      expect(offboard_command.employee.offboarding_infos.count).to eq(0)
    end
  end

end
