require 'rails_helper'

describe EmployeeHelper, type: :helper do
  before :each do
    Timecop.freeze(Time.new(2017, 11, 13, 9, 0, 0, "-08:00"))
  end

  after :each do
    Timecop.return
  end

  context "#offboard_in_progress" do
    let(:offboarding_contractor) { FactoryGirl.create(:contract_worker,
                                   status: "active",
                                   termination_date: nil,
                                   contract_end_date: Date.new(2017, 11, 24)) }
    let(:ongoing_contractor)     { FactoryGirl.create(:contract_worker,
                                   status: "active",
                                   termination_date: nil,
                                   contract_end_date: Date.new(2018, 1, 1)) }

    it "should include contractor with end date within 2 weeks" do
      expect(offboard_in_progress?(offboarding_contractor)).to eq(true)
    end

    it "should not include contractor with end date in future" do
      expect(offboard_in_progress?(ongoing_contractor)).to eq(false)
    end
  end
end
