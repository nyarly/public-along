require 'rails_helper'

RSpec.describe Profile, type: :model do
  let!(:profile) { FactoryGirl.create(:profile, profile_status: "Active") }

  it "should meet validations" do
    expect(profile).to be_valid

    expect(profile).to_not allow_value(nil).for(:start_date)
    expect(profile).to_not allow_value(nil).for(:department_id)
    expect(profile).to_not allow_value(nil).for(:location_id)
    expect(profile).to_not allow_value(nil).for(:worker_type_id)
    expect(profile).to_not allow_value(nil).for(:job_title_id)
    expect(profile).to_not allow_value(nil).for(:employee_id)
    expect(profile).to_not allow_value(nil).for(:adp_employee_id)
  end

  it "should always return the most recent profile for Active" do
    new_profile = FactoryGirl.create(:profile, profile_status: "Active")
    expect(Profile.count).to eq(2)
    expect(Profile.active).to eq(new_profile)
  end
end
