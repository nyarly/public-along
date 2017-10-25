require 'rails_helper'

describe ManagementTreeQuery, type: :query do
  let!(:ceo)             { FactoryGirl.create(:employee) }
  let!(:manager)         { FactoryGirl.create(:employee, last_name: "Aaa", manager: ceo) }
  let!(:manager_2)       { FactoryGirl.create(:employee, last_name: "Bbb", manager: ceo) }
  let!(:direct_report)   { FactoryGirl.create(:employee, last_name: "Ccc", manager: manager) }
  let!(:direct_report_2) { FactoryGirl.create(:employee, last_name: "Ddd", manager: manager_2) }
  let!(:direct_report_3) { FactoryGirl.create(:employee, last_name: "Eee", manager: manager_2) }
  let!(:direct_report_4) { FactoryGirl.create(:employee, last_name: "Eee", manager: direct_report_3) }

  context "for a direct report" do
    it "should get the entire management chain 1" do
      workers = ManagementTreeQuery.new(direct_report_4).call
      expect(workers).to eq([
        direct_report_3.id,
        manager_2.id,
        ceo.id
      ])
    end

    it "should get the entire management chain 2" do
      workers = ManagementTreeQuery.new(direct_report_2).call
      expect(workers).to eq([
        manager_2.id,
        ceo.id
      ])
    end

    it "should get only one" do
      workers = ManagementTreeQuery.new(manager).call
      expect(workers).to eq([ceo.id])
    end

    it "should get no one for the ceo" do
      workers = ManagementTreeQuery.new(ceo).call
      expect(workers).to eq([])
    end
  end
end
