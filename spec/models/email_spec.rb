require 'rails_helper'

RSpec.describe Email, type: :model do
  let(:email) { FactoryGirl.build(:email) }

  it "should meet validations" do
    expect(email).to be_valid
    expect(email).to_not allow_value(nil).for(:mailer)
  end
  
end