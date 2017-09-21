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
    expect(profile).to_not allow_value(nil).for(:employee_id)
    expect(profile).to_not allow_value(nil).for(:adp_employee_id)
  end

  it "should always return the most recent profile for active" do
    profile = FactoryGirl.create(:profile, profile_status: "active")
    expect(Profile.count).to eq(2)
    expect(Profile.active).to eq(profile)
  end

  describe "state machine" do

    it "should initialize as pending" do
      expect(profile).to have_state(:pending)
      expect(profile).to allow_event(:request_manager_action)
      expect(profile).to allow_event(:activate)
      expect(profile).to allow_transition_to(:waiting_for_onboard)
      expect(profile).to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:onboard_received)
      expect(profile).not_to allow_transition_to(:waiting_for_offboard)
      expect(profile).not_to allow_transition_to(:offboard_received)
      expect(profile).not_to allow_transition_to(:terminated)
      expect(profile).not_to allow_event(:receive_manager_action)
      expect(profile).not_to allow_event(:terminate)
    end

    it "should wait for the onboard form" do
      expect(profile).to transition_from(:pending).to(:waiting_for_onboard).on_event(:request_manager_action)
      expect(profile).to have_state(:waiting_for_onboard)
      expect(profile).to allow_event(:receive_manager_action)
      expect(profile).to allow_transition_to(:onboard_received)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:waiting_for_offboard)
      expect(profile).not_to allow_transition_to(:terminated)
      expect(profile).not_to allow_event(:activate)
      expect(profile).not_to allow_event(:terminate)
    end

    it "should receive the onboard form" do
      expect(profile).to transition_from(:waiting_for_onboard).to(:onboard_received).on_event(:receive_manager_action)
      expect(profile).to have_state(:onboard_received)
      expect(profile).to allow_event(:activate)
      expect(profile).to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:waiting_for_onboard)
      expect(profile).not_to allow_transition_to(:waiting_for_offboard)
      expect(profile).not_to allow_transition_to(:terminated)
      expect(profile).not_to allow_transition_to(:offboard_received)
      expect(profile).not_to allow_event(:terminate)
      expect(profile).not_to allow_event(:receive_manager_action)
    end

    it "should activate" do
      expect(profile).to transition_from(:onboard_received).to(:active).on_event(:activate)
      expect(profile).to have_state(:active)
      expect(profile).to allow_event(:terminate)
      expect(profile).to allow_event(:request_manager_action)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:waiting_for_onboard)
      expect(profile).not_to allow_transition_to(:offboard_received)
      expect(profile).not_to allow_event(:receive_manager_action)
      expect(profile).not_to allow_event(:activate)
    end

    it "should wait for offboarding form" do
      expect(TechTableMailer).to receive(:offboard_notice).and_return(mailer)
      expect(mailer).to receive(:deliver_now)
      expect(profile).to transition_from(:active).to(:waiting_for_offboard).on_event(:request_manager_action)
      expect(profile).to have_state(:waiting_for_offboard)
      expect(profile).to allow_event(:receive_manager_action)
      expect(profile).to allow_event(:terminate)
      expect(profile).to allow_transition_to(:terminated)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:waiting_for_onboard)
      expect(profile).not_to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:onboard_recieved)
      expect(profile).not_to allow_event(:request_manager_action)
      expect(profile).not_to allow_event(:activate)
    end

    it "should receive the onboard form" do
      expect(profile).to transition_from(:waiting_for_offboard).to(:offboard_received).on_event(:receive_manager_action)
      expect(profile).to have_state(:offboard_received)
      expect(profile).to allow_event(:terminate)
      expect(profile).to allow_transition_to(:terminated)
      expect(profile).not_to allow_transition_to(:pending)
      expect(profile).not_to allow_transition_to(:onboard_received)
      expect(profile).not_to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:waiting_for_offboard)
      expect(profile).not_to allow_transition_to(:waiting_for_onboard)
      expect(profile).not_to allow_event(:activate)
      expect(profile).not_to allow_event(:request_manager_action)
      expect(profile).not_to allow_event(:receive_manager_action)
    end

    it "should get terminated" do
      expect(profile).to transition_from(:offboard_received).to(:terminated).on_event(:terminate)
      expect(profile).to transition_from(:waiting_for_offboard).to(:terminated).on_event(:terminate)
      expect(profile).to transition_from(:active).to(:terminated).on_event(:terminate)
      expect(profile).to have_state(:terminated)
      expect(profile).to allow_event(:request_manager_action)
      expect(profile).to allow_transition_to(:waiting_for_onboard)
      expect(profile).not_to allow_transition_to(:onboard_received)
      expect(profile).not_to allow_transition_to(:active)
      expect(profile).not_to allow_transition_to(:waiting_for_offboard)
      expect(profile).not_to allow_transition_to(:offboard_received)
      expect(profile).not_to allow_event(:receive_manager_action)
      expect(profile).not_to allow_event(:activate)
      expect(profile).not_to allow_event(:terminate)
    end
  end
end
