require 'rails_helper'

RSpec.describe MachineBundle, type: :model do
  let(:machine_bundle) { FactoryGirl.build(:machine_bundle) }

  it "should meet validations" do
    expect(machine_bundle).to be_valid

    expect(machine_bundle).to_not allow_value(nil).for(:name)
    expect(machine_bundle).to_not allow_value(nil).for(:description)
    expect(machine_bundle).to     validate_uniqueness_of(:name)
  end

  it "should scope contingent machine_bundles by name" do
    cmb = FactoryGirl.create(:machine_bundle, name: "Contingent bundle")
    acmb = FactoryGirl.create(:machine_bundle, name: "Another contingent bundle")
    rmb = FactoryGirl.create(:machine_bundle, name: "Regular ol' bundle")

    expect(MachineBundle.contingent_bundles).to include(cmb)
    expect(MachineBundle.contingent_bundles).to include(acmb)
    expect(MachineBundle.contingent_bundles).to_not include(rmb)
  end
end
