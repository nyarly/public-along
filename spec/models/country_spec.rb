require 'rails_helper'

RSpec.describe Country, type: :model do
  let(:country) { FactoryGirl.build(:country) }

  it "meets validations" do
    expect(country).to be_valid
    expect(country).to_not allow_value(nil).for(:name)
    expect(country).to_not allow_value(nil).for(:iso_alpha_2)
  end
end
