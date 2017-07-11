require 'rails_helper'

describe BetterworksService, type: :service do

  describe "create csv" do

    let(:service) { BetterworksService.new }
    let(:ftr_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTR",
      kind: "Regular")}
    let(:ptr_worker_type) { FactoryGirl.create(:worker_type,
      code: "PTR",
      kind: "Regular")}
    let(:temp_worker_type) { FactoryGirl.create(:worker_type,
      code: "FTT",
      kind: "Temporary")}

    it "should scope only regular employees" do
      ftr_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        hire_date: Date.new(2017, 1, 1))
      ptr_emp = FactoryGirl.create(:employee,
        worker_type: ptr_worker_type,
        hire_date: Date.new(2017, 1, 1))
      temp = FactoryGirl.create(:employee,
        worker_type: temp_worker_type,
        hire_date: Date.new(2017, 1, 1))

      expect(service.betterworks_users.count).to eq(2)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).to include(ptr_emp)
      expect(service.betterworks_users).not_to include(temp)
    end

    it "should not include employees who have not started" do
      ftr_emp = FactoryGirl.create(:employee,
        hire_date: Date.new(2017, 1, 1),
        worker_type: ftr_worker_type)
      ftr_new_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        hire_date: Date.today + 2.weeks)

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_new_emp)
    end

    it "should not include terminated employees" do
      ftr_emp = FactoryGirl.create(:employee,
        hire_date: Date.new(2017, 1, 1),
        worker_type: ftr_worker_type)
      ftr_termed_emp = FactoryGirl.create(:employee,
        worker_type: ftr_worker_type,
        hire_date: Date.new(2017, 1, 1),
        termination_date: Date.new(2017, 5, 4))

      expect(service.betterworks_users.count).to eq(1)
      expect(service.betterworks_users).to include(ftr_emp)
      expect(service.betterworks_users).not_to include(ftr_termed_emp)
    end
  end

end
