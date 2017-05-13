require 'rails_helper'

describe GoogleAppsService, type: :service do
  let(:data_transfer_service) { double(Google::Apis::AdminDatatransferV1::DataTransferService) }
  let(:directory_service) { double(Google::Apis::AdminDirectoryV1::DirectoryService) }
  let(:google_app_service) { GoogleAppsService.new }

  before :each do
    allow(Google::Apis::AdminDatatransferV1::DataTransferService).to receive(:new).and_return(data_transfer_service)
    allow(data_transfer_service).to receive_message_chain(:client_options, :application_name=)
    allow(data_transfer_service).to receive(:application_name)
    allow(data_transfer_service).to receive(:authorization=)

    allow(Google::Apis::AdminDirectoryV1::DirectoryService).to receive(:new).and_return(directory_service)
    allow(directory_service).to receive_message_chain(:client_options, :application_name=)
    allow(directory_service).to receive(:application_name)
    allow(directory_service).to receive(:authorization=)
  end

  context "successfully transfers data" do
    let!(:manager) { FactoryGirl.create(:employee, email: "123@example.com") }
    let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.id, email: "456@example.com") }

    it "should get a success response from the google api" do
      allow(directory_service).to receive_message_chain(:get_user, :id).and_return({"id": "1111"})
      transfers = google_app_service.transfer_data(employee)
      expect(transfers).to eq(stuff)
    end
  end

    context "when the employee does not have offboarding info" do
    end


    # it "should update the app transaction status to 'success'" do
    # end


  # context "fails to transfer google app data" do
  #   it "should get a fail response from the google api" do
  #   end

  #   it "should update the app transaction to 'failed'" do
  #   end
  # end
end
