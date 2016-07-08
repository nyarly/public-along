require 'rails_helper'

RSpec.describe Department, type: :model do
  let(:department) { FactoryGirl.build(:department) }

  it "should meet validations" do
    expect(department).to be_valid

    expect(department).to_not allow_value(nil).for(:name)
    expect(department).to     validate_uniqueness_of(:code).case_insensitive
  end
end
