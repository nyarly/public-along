require 'rails_helper'

describe EmpAccessLevelService, type: :service do
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:security_profile) { FactoryGirl.create(:security_profile) }
  let!(:access_level) { FactoryGirl.create(:access_level) }
  let!(:sec_prof_access_level) { FactoryGirl.create(:sec_prof_access_level,
    access_level_id: access_level.id,
    security_profile_id: security_profile.id) }
  let!(:emp_transaction) { FactoryGirl.create(:emp_transaction,
    employee_id: employee.id)}
  let!(:emp_sec_profile) { FactoryGirl.create(:emp_sec_profile,
    emp_transaction_id: emp_transaction.id,
    security_profile_id: security_profile.id)}

  context "emp security profile does not have an emp access level connection" do

    it "should create an emp access level for an active security profile" do
      EmpAccessLevelService.new(employee)
      expect(employee.emp_access_levels.count).to eq(1)
      expect(employee.emp_access_levels[0].employee_id).to eq(employee.id)
      expect(employee.emp_access_levels[0].access_level_id).to eq(access_level.id)
      expect(employee.emp_access_levels[0].active).to eq(true)
    end
  end

  context "employee has emp access levels" do
    let!(:emp_access_level) { FactoryGirl.create(:emp_access_level,
      employee_id: employee.id,
      access_level_id: access_level.id) }

    it "should not create emp access levels" do
      EmpAccessLevelService.new(employee)
      expect(employee.emp_access_levels.count).to eq(1)
      expect(employee.emp_access_levels[0].employee_id).to eq(employee.id)
      expect(employee.emp_access_levels[0].access_level_id).to eq(access_level.id)
      expect(employee.emp_access_levels[0].active).to eq(true)
    end

  end

end
