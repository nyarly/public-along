require 'rails_helper'

RSpec.describe OnboardingInfo, type: :model do
  let(:onboarding_info) { FactoryGirl.build(:onboarding_info) }

  it "should meet validations" do
    expect(onboarding_info).to be_valid

    expect(onboarding_info).to_not allow_value(nil).for(:employee_id)
    expect(onboarding_info).to_not allow_value(nil).for(:buddy_id)
  end
end
