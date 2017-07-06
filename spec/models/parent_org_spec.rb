require 'rails_helper'

RSpec.describe ParentOrg, type: :model do
  let(:parent_org) { FactoryGirl.create(:parent_org) }

  it "should meet validations" do
    expect(parent_org).to be_valid

    expect(parent_org).to_not allow_value(nil).for(:name)
    expect(parent_org).to_not allow_value(nil).for(:code)
    expect(parent_org).to     validate_uniqueness_of(:code)
  end
end
