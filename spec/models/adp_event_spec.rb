require 'rails_helper'

RSpec.describe AdpEvent, type: :model do
  let!(:adp_event) { FactoryGirl.build(:adp_event) }

  after :each do
    Timecop.return
  end

  it "should have validations" do
    expect(adp_event).to be_valid

    expect(adp_event).to_not allow_value(nil).for(:json)
    expect(adp_event).to_not allow_value(nil).for(:msg_id)
  end

  context "with new hire/rehire events" do
    let!(:json)             { File.read(Rails.root.to_s+"/spec/fixtures/adp_rehire_event.json") }
    let!(:prccd_hire_evt)   { FactoryGirl.create(:adp_event,
                              status: "Processed",
                              kind: "worker.hire")}
    let!(:new_hire_evt)     { FactoryGirl.create(:adp_event,
                              status: "New",
                              json: json,
                              kind: "worker.hire")}
    let!(:prccd_rehire_evt) { FactoryGirl.create(:adp_event,
                              status: "Processed",
                              kind: "worker.rehire")}
    let!(:new_rehire_evt)   { FactoryGirl.create(:adp_event,
                              json: json,
                              status: "New",
                              kind: "worker.rehire")}
    let(:profiler)          { EmployeeProfile.new }
    let!(:reg_wt)           { FactoryGirl.create(:worker_type,
                              code: "FTR")}

    it "should get unprocessed new hires" do
      expect(AdpEvent.unprocessed_onboard_evts).to eq([new_hire_evt, new_rehire_evt])
    end

    it "should get unprocessed new hires to be sent reminders" do
      Timecop.freeze(Time.new(2018, 8, 23, 17, 0, 0, "+00:00"))
      expect(AdpEvent.onboarding_reminder_group).to eq([new_hire_evt, new_rehire_evt])
    end
  end
end
