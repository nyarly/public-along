require 'rails_helper'
require 'aasm/rspec'

RSpec.describe Profile, type: :model do
  let!(:profile) { FactoryGirl.create(:profile) }
  let(:mailer)   { double(TechTableMailer) }

  it "should meet validations" do
    expect(profile).to be_valid

    expect(profile).to_not allow_value(nil).for(:start_date)
    expect(profile).to_not allow_value(nil).for(:department_id)
    expect(profile).to_not allow_value(nil).for(:location_id)
    expect(profile).to_not allow_value(nil).for(:worker_type_id)
    expect(profile).to_not allow_value(nil).for(:job_title_id)
    expect(profile).to_not allow_value(nil).for(:employee)
  end

  describe "state machine" do

    it "should initialize as pending" do
      expect(profile).to have_state(:pending)
      expect(profile).to allow_event(:activate)
      expect(profile).to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:terminated)
      expect(profile).not_to allow_transition_to(:leave)
      expect(profile).not_to allow_event(:terminate)
      expect(profile).not_to allow_event(:start_leave)
    end

    it "should activate" do
      expect(profile).to transition_from(:pending).to(:active).on_event(:activate)
      expect(profile).to have_state(:active)
      expect(profile).to allow_event(:terminate)
      expect(profile).not_to allow_transition_to(:pending)
    end

    it "should receive go on leave" do
      expect(profile).to transition_from(:active).to(:leave).on_event(:start_leave)
      expect(profile).to have_state(:leave)
      expect(profile).to allow_event(:activate)
      expect(profile).to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:pending)
    end

    it "should return from leave" do
      expect(profile).to transition_from(:leave).to(:active).on_event(:activate)
      expect(profile).to have_state(:active)
      expect(profile).to allow_event(:terminate)
      expect(profile).to allow_event(:start_leave)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:created)
    end

    it "should get terminated" do
      expect(profile).to transition_from(:active).to(:terminated).on_event(:terminate)
      expect(profile).to have_state(:terminated)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:active)
      expect(profile).not_to allow_event(:activate)
      expect(profile).not_to allow_event(:start_leave)
    end
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
