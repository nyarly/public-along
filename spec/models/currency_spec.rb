require 'rails_helper'

RSpec.describe Currency, type: :model do
  let(:currency) { FactoryGirl.build(:currency) }

  it "meets validations" do
    expect(currency).to be_valid
    expect(currency).to_not allow_value(nil).for(:name)
    expect(currency).to_not allow_value(nil).for(:iso_alpha_code)
  end
end
