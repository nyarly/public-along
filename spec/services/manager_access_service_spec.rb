require 'rails_helper'

describe ManagerAccessService, type: :service do
  let!(:manager_sec_prof) { FactoryGirl.create(:security_profile, name: "Basic Manager") }

  context "manager security profile update" do
    let!(:manager_needs_update) { FactoryGirl.create(:active_employee) }
    let!(:profile)              { FactoryGirl.create(:active_profile,
                                  employee: manager_needs_update,
                                  management_position: true) }

    it "should update when the worker has a management position and doesn't have profile" do
      results = ManagerAccessService.new(manager_needs_update).process!
      expect(results).to include(manager_sec_prof)
    end
  end

  context "no security profile update" do
    let!(:manager_no_update) { FactoryGirl.create(:active_employee) }
    let!(:profile_1)         { FactoryGirl.create(:active_profile,
                               employee: manager_no_update,
                               management_position: true) }
    let!(:emp_transaction)   { FactoryGirl.create(:emp_transaction,
                               employee: manager_no_update,
                               kind: "Security Access") }
    let!(:emp_sec_prof)      { FactoryGirl.create(:emp_sec_profile,
                               emp_transaction: emp_transaction) }
    let!(:no_update)         { FactoryGirl.create(:active_employee) }
    let!(:profile_2)         { FactoryGirl.create(:active_profile,
                               employee: no_update,
                               management_position: false) }

    it "should not change when manager already has the basic manager profile" do
      results = ManagerAccessService.new(manager_no_update).process!
      expect(results).to include(manager_sec_prof)
    end

    it "should not change when worker is not a manager" do
      results = ManagerAccessService.new(no_update).process!
      expect(results).not_to include(manager_sec_prof)
    end
  end

end
