require 'rails_helper'

describe GoogleAppsService, type: :service do
  let!(:employee) { FactoryGirl.create(:employee) }

  describe "successfully transfers google app data" do

    context "when the employee has offboarding info" do
      let!(:emp_transaction) { FactoryGirl.create(:emp_transaction) }
      let!(:offboarding_info) { FactoryGirl.create(:offboarding_info, emp_transction: emp_transaction.id, employee_id: employee.id, transfer_google_docs_id: 1) }

      it "should get a success response from the google api" do
        transfer_google = GoogleAppsService.new(employee)
        expect(transfer_google).to eq(true)

      end
    end

    context "when the employee does not have offboarding info" do
    end


    # it "should update the app transaction status to 'success'" do
    # end
  end

  # context "fails to transfer google app data" do
  #   it "should get a fail response from the google api" do
  #   end

  #   it "should update the app transaction to 'failed'" do
  #   end
  # end
end
