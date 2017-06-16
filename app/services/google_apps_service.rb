require 'google/apis/admin_datatransfer_v1'
require 'google/apis/admin_directory_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class GoogleAppsService

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Mezzo'
  SCOPE = [ Google::Apis::AdminDatatransferV1::AUTH_ADMIN_DATATRANSFER,
            Google::Apis::AdminDirectoryV1::AUTH_ADMIN_DIRECTORY_USER ]

  def initialize
    Google::Apis::RequestOptions.default.authorization = authorize
    Google::Apis::RequestOptions.default.retries = 5

    @data_transfer_service ||= begin
      service = Google::Apis::AdminDatatransferV1::DataTransferService.new
      service.client_options.application_name = APPLICATION_NAME
      service
    end

    @directory_service ||= begin
      service = Google::Apis::AdminDirectoryV1::DirectoryService.new
      service.client_options.application_name = APPLICATION_NAME
      service
    end
  end

  def transfer_data(employee)
    transfer_info = TransitionInfo::Offboard.new(employee.employee_id)
    transfer_email = transfer_info.forward_google
    user_account = google_user(employee.email)
    transfer_account = google_user(transfer_email)
    app_list = get_app_list

    if user_account && transfer_account
      if app_list && app_list.applications.present?
        app_list.applications.each do |application|
          if application.name == "Drive and Docs"
            app_data = Google::Apis::AdminDatatransferV1::ApplicationDataTransfer.new(
              application_id: application.id,
              application_transfer_params: application.transfer_params)

            dto = Google::Apis::AdminDatatransferV1::DataTransfer.new(
              old_owner_user_id: user_account.id,
              new_owner_user_id: transfer_account.id,
              application_data_transfers: [app_data])

            transfer_response = @data_transfer_service.insert_transfer(dto)
            transfer_response
          end
        end
      end
    end
  end

  def confirm_transfer(transfer_id)
    begin
      @data_transfer_service.get_transfer(transfer_id)
    rescue => e
      Rails.logger.error "Google Apps confirm transfer error."
      Rails.logger.error "Google Apps responded with: #{e}"
      e
    end
  end

  def google_user(employee_email)
    begin
      @directory_service.get_user(employee_email)
    rescue => e
      Rails.logger.error "Google Apps User #{employee_email} not found."
      Rails.logger.error "Google Apps responded with: #{e}"
      nil
    end
  end

  def get_app_list
    # List the first 10 applications available for transfer.
    begin
      @data_transfer_service.list_applications(max_results: 10)
    rescue => e
      Rails.logger.error "Google Apps List failed with: #{e}"
      nil
    end
  end

  private

  def authorize
    FileUtils.mkdir_p(File.dirname(SECRETS.google_cred_path))

    client_id = Google::Auth::ClientId.new(SECRETS.google_client_id, SECRETS.google_client_secret)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: SECRETS.google_cred_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    credentials = authorizer.get_credentials(SECRETS.google_user_id)

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
        user_id: SECRETS.google_user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
