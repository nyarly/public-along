require 'rails_helper'

RSpec.describe EmpSecProfile, type: :model do
  let(:emp_sec_profile) { FactoryGirl.build(:emp_sec_profile) }

  it "should meet validations" do
    expect(emp_sec_profile).to be_valid

    expect(emp_sec_profile).to_not allow_value(nil).for(:employee_id)
    expect(emp_sec_profile).to_not allow_value(nil).for(:security_profile_id)
  end
end
