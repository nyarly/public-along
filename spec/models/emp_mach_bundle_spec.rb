require 'rails_helper'

RSpec.describe EmpMachBundle, type: :model do
  let(:emp_mach_bundle) { FactoryGirl.build(:emp_mach_bundle) }

  it "should meet validations" do
    expect(emp_mach_bundle).to be_valid

    expect(emp_mach_bundle).to_not allow_value(nil).for(:employee_id)
    expect(emp_mach_bundle).to_not allow_value(nil).for(:machine_bundle_id)
  end
end
