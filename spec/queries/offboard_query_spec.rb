require 'rails_helper'

describe OffboardQuery, type: :query do
  let(:parent_org_a)    { FactoryGirl.create(:parent_org, name: "Aaa") }
  let(:parent_org_b)    { FactoryGirl.create(:parent_org, name: "Bbb") }

  let(:dept_c)          { FactoryGirl.create(:department,
                          name: "Ccc",
                          parent_org: parent_org_a) }
  let(:dept_d)          { FactoryGirl.create(:department,
                          name: "Ddd",
                          parent_org: parent_org_b) }
  let(:dept_e)          { FactoryGirl.create(:department,
                          name: "Eee",
                          parent_org: parent_org_b) }

  let(:offboarded)      { FactoryGirl.create(:employee,
                          termination_date: Date.new(2017, 12, 10),
                          status: "terminated") }
  let!(:offboarded_p)   { FactoryGirl.create(:profile,
                          profile_status: "terminated",
                          employee: offboarded,
                          department: dept_e) }
  let(:offboarded_2)    { FactoryGirl.create(:employee,
                          termination_date: Date.new(2017, 12, 10),
                          status: "terminated") }
  let!(:offboarded_2_p) { FactoryGirl.create(:profile,
                          profile_status: "terminated",
                          employee: offboarded_2,
                          department: dept_c) }

  let(:offboarding)     { FactoryGirl.create(:employee,
                          status: "active",
                          termination_date: Date.new(2017, 12, 11)) }
  let!(:offboarding_p)  { FactoryGirl.create(:profile,
                          employee: offboarding,
                          profile_status: "active",
                          department: dept_e) }
  let(:old_offboard)    { FactoryGirl.create(:employee,
                          last_name: "Aaa",
                          status: "terminated",
                          termination_date: Date.new(2017, 12, 06)) }
  let!(:old_offboard_p) { FactoryGirl.create(:profile,
                          employee: old_offboard,
                          profile_status: "terminated",
                          start_date: Date.new(2017, 12, 06),
                          department: dept_c) }
  let(:old_offb_2)      { FactoryGirl.create(:employee,
                          last_name: "Aaa",
                          status: "terminated",
                          termination_date: Date.new(2017, 11, 24)) }
  let!(:old_offb_2_p)   { FactoryGirl.create(:profile,
                          employee: old_offb_2,
                          profile_status: "terminated",
                          department: dept_d) }

  after :each do
    Timecop.return
  end

  context "#added_and_updated_offboards" do
    it "should get the pending workers in the correct order" do
      Timecop.freeze(Time.new(2017, 12, 11, 0, 0, 0, "+16:00"))
      query = OffboardQuery.new.added_and_updated_offboards
      expect(query).to eq([offboarded_2_p, offboarded_p])
    end
  end
end
