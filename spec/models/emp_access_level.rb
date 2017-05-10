require 'rails_helper'

RSpec.describe EmpAccessLevel, type: :model do
  let!(:employee) { FactoryGirl.create(:employee) }
  let!(:access_level) { FactoryGirl.create(:access_level) }
  let!(:emp_access_level) { FactoryGirl.create(:emp_access_level, employee_id: employee.id, access_level_id: access_level.id) }

  it "should meet validations" do
    expect(emp_access_level).to be(valid)

    expect(emp_access_level).to_not allow_value(nil).for(:access_level_id)
    expect(emp_access_level).to_not allow_value(nil).for(:employee_id)
  end
end
