require 'rails_helper'

RSpec.describe BusinessUnit, type: :model do
  let(:business_unit) { FactoryGirl.create(:business_unit) }

  it 'is valid' do
    expect(business_unit).to be_valid
  end

  it 'meets name presence validation' do
    expect(business_unit).not_to allow_value(nil).for(:name)
  end

  it 'meets code validation' do
    expect(business_unit).not_to allow_value(nil).for(:code)
  end
end
