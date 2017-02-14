require 'rails_helper'

RSpec.describe Location, type: :model do
  let(:location) { FactoryGirl.build(:location) }

  it "should meet validations" do
    expect(location).to be_valid

    expect(location).to_not allow_value(nil).for(:name)
    expect(location).to_not allow_value(nil).for(:code)
    expect(location).to_not allow_value(nil).for(:kind)
    expect(location).to_not allow_value(nil).for(:country)
    expect(location).to     validate_uniqueness_of(:code)
  end
end
