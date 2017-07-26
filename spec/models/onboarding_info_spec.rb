require 'rails_helper'

RSpec.describe OnboardingInfo, type: :model do
  let(:onboarding_info) { FactoryGirl.build(:onboarding_info) }

  it "should meet validations" do
    expect(onboarding_info).to be_valid
  end
end
