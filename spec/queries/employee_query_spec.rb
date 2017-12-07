require 'rails_helper'

describe EmployeeQuery, type: :query do
  context "#contract_end_reminder_group" do
    let!(:contractor) { FactoryGirl.create(:contract_worker,
                        status: "active",
                        request_status: "none",
                        contract_end_date: Date.new(2017, 12, 01),
                        termination_date: nil) }
    let!(:cont_2)     { FactoryGirl.create(:contract_worker,
                        status: "active",
                        contract_end_date: Date.new(2017, 11, 11),
                        termination_date: Date.new(2017, 12, 01)) }

    after :each do
      Timecop.return
    end

    it "should get the correct contractors" do
      Timecop.freeze(Time.new(2017, 11, 17, 17, 0, 0, "+00:00"))
      expect(EmployeeQuery.new.contract_end_reminder_group).to eq([contractor])
    end
  end
end
