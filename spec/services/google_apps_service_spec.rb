require 'rails_helper'

describe GoogleAppsService, type: :service do
  let(:data_transfer_service) { double(Google::Apis::AdminDatatransferV1::DataTransferService) }
  let(:data_transfer) { double(Google::Apis::AdminDatatransferV1::DataTransfer) }
  let(:directory_service) { double(Google::Apis::AdminDirectoryV1::DirectoryService) }
  let(:api) { double(Google::Apis::RequestOptions) }
  let(:authorizer) { double(Google::Auth::UserAuthorizer) }
  let(:google_app_service) { GoogleAppsService.new }

  before :each do
    allow(Google::Apis::AdminDatatransferV1::DataTransferService).to receive(:new).and_return(data_transfer_service)
    allow(data_transfer_service).to receive_message_chain(:client_options, :application_name=)
    allow(data_transfer_service).to receive(:list_applications)

    allow(Google::Apis::AdminDirectoryV1::DirectoryService).to receive(:new).and_return(directory_service)
    allow(directory_service).to receive_message_chain(:client_options, :application_name=)

    allow(Google::Apis::RequestOptions).to receive(:default).and_return(api)
    allow(api).to receive(:authorization=)
    allow(api).to receive(:retries=)

    allow(Google::Auth::UserAuthorizer).to receive(:new).and_return(authorizer)
    allow(authorizer).to receive(:get_credentials).and_return("okay")
    allow(authorizer).to receive(:get_authorization_url)
    allow(authorizer).to receive(:get_and_store_credentials_from_code)

    allow(Google::Apis::AdminDatatransferV1::DataTransfer).to receive(:new).and_return(data_transfer)
  end

  context "successfully transfers data" do
    let(:manager) { FactoryGirl.create(:regular_employee) }
    let(:employee) { FactoryGirl.create(:employee,
      email: "something@example.com") }
    let!(:profile) { FactoryGirl.create(:profile,
      employee: employee,
      manager_id: manager.employee_id) }

    application = OpenStruct.new(id: "12345", name: "Drive and Docs", transfer_params: ["stuff"])
    applications = OpenStruct.new(applications: [application])
    user = OpenStruct.new(id: "some google id")

    it "should respond with an array of data transfers" do
      expect(data_transfer_service).to receive(:list_applications).and_return(applications)
      expect(directory_service).to receive(:get_user).with(employee.email).and_return(user)
      expect(directory_service).to receive(:get_user).with(manager.email).and_return(user)
      expect(data_transfer_service).to receive(:insert_transfer).with(data_transfer).and_return("something")
      transfers = google_app_service.transfer_data(employee)
      expect(transfers).to eq(["something"])
    end
  end
end
