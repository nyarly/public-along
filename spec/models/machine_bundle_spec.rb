require 'rails_helper'

RSpec.describe MachineBundle, type: :model do
  let(:machine_bundle) { FactoryGirl.build(:machine_bundle) }

  it "should meet validations" do
    expect(machine_bundle).to be_valid

    expect(machine_bundle).to_not allow_value(nil).for(:name)
    expect(machine_bundle).to_not allow_value(nil).for(:description)
    expect(machine_bundle).to     validate_uniqueness_of(:name)
  end
end
