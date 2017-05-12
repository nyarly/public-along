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


  def initialize(employee)
    @employee = employee
    @transfer_to_employee = transfer_to_employee

    transfer_data
  end

  private

  def transfer_data
    service = Google::Apis::AdminDatatransferV1::DataTransferService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize

    # List the first 10 applications available for transfer.
    response = service.list_applications(max_results: 10)

    response.applications.each do |application|
      if application.name == "Drive and Docs"

        dto = Google::Apis::AdminDatatransferV1::DataTransfer.new(
          kind: "admin#datatransfer#DataTransfer",
          old_owner_user_id: user_id(@employee),
          new_owner_user_id: user_id(@transfer_to_employee),
          application_data_transfers: [
            {
              application_id: application.id
            }
          ]
        )

        service.insert_transfer(dto)
      end
    end
  end

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(
        base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def transfer_to_employee
    offboarding_info = @employee.offboarding_infos.last

    if offboarding_info.present? && offboarding_info.transfer_google_docs_id.present?
      Employee.find(offboarding_info.transfer_google_docs_id)
    else
      Employee.find_by(employee_id: @employee.manager_id)
    end

  end

  def user_id(user)
    service = Google::Apis::AdminDirectoryV1::DirectoryService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize

    service.get_user(user.email).id
  end

end
