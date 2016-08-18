require 'rails_helper'

RSpec.describe AccessLevel, type: :model do
  let(:access_level) { FactoryGirl.build(:access_level) }

  it "should meet validations" do
    expect(access_level).to be_valid

    expect(access_level).to_not allow_value(nil).for(:name)
    expect(access_level).to_not allow_value(nil).for(:application_id)
  end
end
