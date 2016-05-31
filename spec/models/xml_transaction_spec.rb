require 'rails_helper'

describe XmlTransaction, type: :model do
  let!(:xml_transaction) { FactoryGirl.build(:xml_transaction) }
  it "should have validations" do
    expect(xml_transaction).to be_valid

    expect(xml_transaction).to_not allow_value(nil).for(:name)
    expect(xml_transaction).to_not allow_value(nil).for(:checksum)
    should validate_uniqueness_of(:checksum)
  end
end
