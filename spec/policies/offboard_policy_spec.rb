require 'rails_helper'

describe OffboardPolicy, type: :policy do
  context "offboarded contractor" do
    let(:offboarded_contractor) { FactoryGirl.create(:employee,
                                  status: "terminated",
                                  contract_end_date: 1.day.ago,
                                  termination_date: nil) }
    let(:offboarded_c_profile)  { FactoryGirl.create(:profile,
                                  employee: offboarded_contractor,
                                  profile_status: "terminated",
                                  end_date: 1.day.ago) }
    let(:contractor)            { FactoryGirl.create(:employee,
                                  status: "active",
                                  contract_end_date: 1.week.from_now,
                                  termination_date: nil) }
    let(:contractor_profile)    { FactoryGirl.create(:profile,
                                  employee: contractor,
                                  profile_status: "active",
                                  end_date: nil) }

    it "#offboarded_contractor?" do
      already_offboarded = OffboardPolicy.new(offboarded_contractor).offboarded_contractor?
      not_offboarded = OffboardPolicy.new(contractor).offboarded_contractor?

      expect(already_offboarded).to be(true)
      expect(not_offboarded).to be(false)
    end
  end
end
