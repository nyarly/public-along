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

  it "should scope the correct onboarding group" do
    onboarding_group = [
      FactoryGirl.create(:profile, start_date: Date.yesterday),
      FactoryGirl.create(:profile, start_date: Date.today),
      FactoryGirl.create(:profile, start_date: Date.tomorrow)
    ]

    non_onboarding_group = [
      FactoryGirl.create(:profile, start_date: 1.week.ago),
      FactoryGirl.create(:profile, start_date: 2.days.ago),
      FactoryGirl.create(:profile, start_date: 2.days.from_now),
      FactoryGirl.create(:profile, start_date: 1.week.from_now)
    ]

    expect(Profile.onboarding_group).to eq(onboarding_group)
    expect(Profile.onboarding_group).to_not include(non_onboarding_group)
  end
end
