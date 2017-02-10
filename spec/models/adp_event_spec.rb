require 'rails_helper'

RSpec.describe AdpEvent, type: :model do
  let!(:adp_event) { FactoryGirl.build(:adp_event) }
  it "should have validations" do
    expect(adp_event).to be_valid

    expect(adp_event).to_not allow_value(nil).for(:json)
    expect(adp_event).to_not allow_value(nil).for(:msg_id)
  end
end
