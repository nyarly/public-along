require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:transaction) { FactoryGirl.build(:transaction) }

  it "should meet validations" do
    expect(transaction).to be_valid

    expect(transaction).to_not allow_value(nil).for(:type)
    expect(transaction).to_not allow_value(nil).for(:user_id)
  end
end
