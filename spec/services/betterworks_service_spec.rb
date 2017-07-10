require 'rails_helper'

describe BetterworksService, type: :service do

  describe "create csv" do

    let(:service) { BetterworksService.new }
    let(:ftr_worker_type) { FactoryGirl.create(:worker_type, code: "FTR", kind: "Regular")}
    let(:ptr_worker_type) { FactoryGirl.create(:worker_type, code: "PTR", kind: "Regular")}
    let(:temp_worker_type) { FactoryGirl.create(:worker_type, code: "FTT", kind: "Temporary")}

    it "should scope only regular employees" do
      ftr_emp = FactoryGirl.create(:employee, worker_type: ftr_worker_type)
      ptr_emp = FactoryGirl.create(:employee, worker_type: ptr_worker_type)
      temp = FactoryGirl.create(:employee, worker_type: temp_worker_type)

      expect(service.get_employees.count).to eq(2)
      expect(service.get_employees).to include(ftr_emp)
      expect(service.get_employees).to include(ptr_emp)
      expect(service.get_employees).not_to include(temp)
    end

    it "should not include any employee with a termination date" do
      ftr_emp = FactoryGirl.create(:employee, worker_type: ftr_worker_type)

    end
  end

end
