require 'rails_helper'

describe GoogleAppsService, type: :service do
  let(:data_transfer_service) { double(Google::Apis::AdminDatatransferV1::DataTransferService) }
  let(:directory_service) { double(Google::Apis::AdminDirectoryV1::DirectoryService) }
  let(:google_app_service) { GoogleAppsService.new }

  def mock_application
    application_transfer_param = Google::Apis::AdminDatatransferV1::ApplicationTransferParam.new
    application_transfer_param.key = "PRIVACY_LEVEL"
    application_transfer_param.value = ["SHARED", "PRIVATE"]

    application = Google::Apis::AdminDatatransferV1::Application.new
    application.id = "55656082996"
    application.name = "Drive and Docs"
    application.transfer_params = [application_transfer_param]

    response = Google::Apis::AdminDatatransferV1::ApplicationsListResponse.new
    response.applications = [application]
    return response
  end

  def mock_transfer_pending
    transfer = Google::Apis::AdminDatatransferV1::DataTransfer.new
    app_transfer = Google::Apis::AdminDatatransferV1::ApplicationDataTransfer.new
    app_transfer.application_transfer_status = "pending"
    transfer.application_data_transfers = [app_transfer]
    return transfer
  end

  def mock_transfer_completed
    transfer = Google::Apis::AdminDatatransferV1::DataTransfer.new
    transfer.overall_transfer_status_code = "completed"
    return transfer
  end

  before :each do
    allow(Google::Apis::AdminDatatransferV1::DataTransferService).to receive(:new).and_return(data_transfer_service)
    allow(data_transfer_service).to receive_message_chain(:client_options, :application_name=)
    allow(data_transfer_service).to receive(:application_name)
    allow(data_transfer_service).to receive(:authorization=)
    allow(data_transfer_service).to receive(:list_applications).and_return(mock_application)
    allow(data_transfer_service).to receive(:insert_transfer).and_return(mock_transfer_pending)
    allow(data_transfer_service).to receive(:get_transfer).and_return(mock_transfer_completed)

    allow(Google::Apis::AdminDirectoryV1::DirectoryService).to receive(:new).and_return(directory_service)
    allow(directory_service).to receive_message_chain(:client_options, :application_name=)
    allow(directory_service).to receive(:application_name)
    allow(directory_service).to receive(:authorization=)
  end

  context "successfully transfers data" do
    let!(:manager) { FactoryGirl.create(:employee, email: "123@example.com") }
    let!(:employee) { FactoryGirl.create(:employee, manager_id: manager.employee_id, email: "456@example.com") }

    it "should get a success response from the google api" do
      allow(directory_service).to receive_message_chain(:get_user, :id).and_return({"id": "1111"})
      transfers = google_app_service.transfer_data(employee)
      expect(transfers[0]).to eq("completed")
    end
  end


  context "fails to transfer google app data" do
    it "should get a fail response from the google api" do
    end

    it "should update the app transaction to 'failed'" do
    end
  end
end
