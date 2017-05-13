require 'google/apis/admin_datatransfer_v1'
require 'google/apis/admin_directory_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class GoogleAppsService

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Mezzo'
  CLIENT_SECRETS_PATH = 'client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "admin-datatransfer.yaml")
  SCOPE = [ Google::Apis::AdminDatatransferV1::AUTH_ADMIN_DATATRANSFER, Google::Apis::AdminDirectoryV1::AUTH_ADMIN_DIRECTORY_USER ]


  def initialize
    @data_transfer_service ||= begin
      service = Google::Apis::AdminDatatransferV1::DataTransferService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize
      service
    end

    @directory_service ||= begin
      service = Google::Apis::AdminDirectoryV1::DirectoryService.new
      service.client_options.application_name = APPLICATION_NAME
      service.authorization = authorize
      service
    end

    @errors = {}
  end

  def transfer_data(employee)
    transfer_to_employee = Employee.transfer_google_docs_id(employee)
    puts Employee.transfer_google_docs_id(employee)

    employee_user_id = @directory_service.get_user(employee.email).id
    transfer_to_user_id = @directory_service.get_user(transfer_to_employee.email).id

    # List the first 10 applications available for transfer.
    app_list = @data_transfer_service.list_applications(max_results: 10)

    app_list.applications.each do |application|
      if application.name == "Drive and Docs"
        app_data = Google::Apis::AdminDatatransferV1::ApplicationDataTransfer.new(
          application_id: application.id,
          application_transfer_params: application.transfer_params)

        dto = Google::Apis::AdminDatatransferV1::DataTransfer.new(
          old_owner_user_id: employee_user_id,
          new_owner_user_id: transfer_to_user_id,
          application_data_transfers: [app_data])

        @data_transfer_service.insert_transfer(dto)
      end
    end
  end

  private

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)

    # If authorization expires, run Google Apps Service from the command line
    # The terminal will print a url, which an admin must visit in the browser
    # The browser will display an access code, which will need to be put into the terminal

    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
