require 'rails_helper'

RSpec.describe SecurityProfile, type: :model do
  let(:security_profile) { FactoryGirl.build(:security_profile) }

  it "should meet validations" do
    expect(security_profile).to be_valid

    expect(security_profile).to_not allow_value(nil).for(:name)
  end
end
