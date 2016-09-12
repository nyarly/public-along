require 'rails_helper'

RSpec.describe OffboardingInfo, type: :model do
  let(:offboarding_info) { FactoryGirl.build(:offboarding_info) }

  it "should meet validations" do
    expect(offboarding_info).to be_valid

    expect(offboarding_info).to_not allow_value(nil).for(:employee_id)
    expect(offboarding_info).to_not allow_value(nil).for(:forward_email_id)
    expect(offboarding_info).to_not allow_value(nil).for(:reassign_salesforce_id)
  end
end
