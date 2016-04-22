require 'rails_helper'

describe Employee, type: :model do
  let(:employee) { FactoryGirl.build(:employee) }

  it "should meet validations" do 
    expect(employee).to be_valid

    expect(employee).to_not allow_value(nil).for(:first_name)
    expect(employee).to_not allow_value(nil).for(:last_name)

    expect(employee).to_not allow_value(nil).for(:email)
    expect(employee).to validate_uniqueness_of(:email).case_insensitive
  end
end
