require 'rails_helper'

RSpec.describe WorkerType, type: :model do
  let(:worker_type) { FactoryGirl.create(:worker_type) }

  it "should meet validations" do
    expect(worker_type).to be_valid

    expect(worker_type).to_not allow_value(nil).for(:name)
    expect(worker_type).to_not allow_value(nil).for(:code)
    expect(worker_type).to_not allow_value(nil).for(:kind)

    expect(worker_type).to     validate_uniqueness_of(:code)
  end
end
