require 'rails_helper'

RSpec.describe ContractorInfo, type: :model do
  let(:contractor_info) { FactoryGirl.build(:contractor_info) }

  it 'is valid' do
    expect(contractor_info).to be_valid
  end

  it 'meets emp transaction presence validation' do
    expect(contractor_info).not_to allow_value(nil).for(:emp_transaction)
  end
end
