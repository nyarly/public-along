require 'rails_helper'

describe GoogleAppsService, type: :service do
  let!(:employee) { FactoryGirl.create(:employee, termination_date: Date.new(2017, 6, 1)) }
  let!(:emp_transaction) { FactoryGirl.create(:emp_transaction) }
  let!(:offboarding_info) { FactoryGirl.create(:offboarding_info, emp_transction: emp_transaction.id, employee_id: employee.id, ) }
  let!(:app_transaction) { FactoryGirl.create(:app_transaction, emp_transaction_id: emp_transaction.id, status: "Pending") }

  Timecop.freeze(Time.new(2017, 6, 01, 15, 30, 0, "+00:00"))

  context "successfully transfers google app data" do
    it "should get a success response from the google api" do
    end

    it "should update the app transaction status to 'success'" do
    end
  end

  context "fails to transfer google app data" do
    it "should get a fail response from the google api" do
    end

    it "should update the app transaction to 'failed'" do
    end
  end
end
