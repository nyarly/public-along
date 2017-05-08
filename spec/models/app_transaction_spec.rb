require 'rails_helper'

RSpec.describe AppTransaction, type: :model do
  let(:app_transaction) { FactoryGirl.build(:app_transaction) }

  it "should meet validations" do
    expect(app_transaction).to be_valid

    expect(app_transaction).to_not allow_value(nil).for(:emp_transaction_id)
    expect(app_transaction).to_not allow_value(nil).for(:application_id)
  end
end
