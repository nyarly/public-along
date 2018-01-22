require 'rails_helper'

RSpec.describe Address, type: :model do
  let(:address) { FactoryGirl.build(:address) }

  it "meets validations" do
    expect(address).to be_valid
  end
end
