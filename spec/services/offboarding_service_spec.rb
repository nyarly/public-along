require 'rails_helper'

describe OffboardingService, type: :service do
  let(:manager) { FactoryGirl.create(:employee) }
  let(:employee) { FactoryGirl.create(:employee, manager_id: manager.id, termination_date: Date.new(2017, 6, 1)) }
  let(:sql_service) { double(SqlService) }
  let(:google_apps) { double(GoogleAppsService) }
  let(:offboard_service) { OffboardingService.new }

  before :each do
    allow(SqlService).to receive(:new).and_return(sql_service)
    allow(GoogleAppsService).to receive(:new).and_return(google_apps)
  end

  context "completes" do
    it "should successfully return offboard results" do
      expect(google_apps).to receive(:process).with(employee).and_return("completed")
      expect(sql_service).to receive(:deactivate_all).with(employee).and_return({"Admin" => "success"})
      offboarded_emps = offboard_service.offboard([employee])
      expect(offboarded_emps).to eq([{"Google Apps"=>"completed", "Admin"=>"success"}])
    end
  end
end
