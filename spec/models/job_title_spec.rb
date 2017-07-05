require 'rails_helper'

RSpec.describe JobTitle, type: :model do
  let(:job_title) { FactoryGirl.build(:job_title) }

  it "should meet validations" do
    expect(job_title).to be_valid

    expect(job_title).to_not allow_value(nil).for(:code)
    expect(job_title).to_not allow_value(nil).for(:name)
    expect(job_title).to_not allow_value(nil).for(:status)
  end
end
