require 'rails_helper'

RSpec.describe Application, type: :model do
  let(:application) { FactoryGirl.build(:application) }

  it "should meet validations" do
    expect(application).to be_valid

    expect(application).to_not allow_value(nil).for(:name)
  end
end
