require 'net/sftp'
require 'gpgme'

# Concur Data SFTP Transfer
# Upload daily before 6pm PT
# Processed by Concur between 6pm and 3am PT
module ConcurImporter
  class Upload

    def all
      verify_directory
      generate_lists
      generate_employee_import(daily_upload) unless daily_upload.blank?
      encrypt_all
      upload_files(encrypted_files)
    end

    def encrypt_and_upload_single_file(filepath)
      encrypt(filepath)
      upload_files([encrypted_filepath(filepath)])
    end

    # Warning: Updates all active employee records in Concur.
    # Intended for initial upload, not for regular use.
    def initial_concur_sync
      verify_directory
      generate_lists
      generate_employee_import(initial_upload) unless initial_upload.blank?
      encrypt_all
      upload_files(encrypted_files)
    end

    private

    def upload_files(files)
      Net::SFTP.start(uri.host, SECRETS.concur_entity_code, password: password, port: port) do |sftp|
        files.each do |file|
          remote = remote_filepath(file)
          sftp.upload!(file, remote)
        end
      end
    end

    def encrypt(filepath)
      input = File.read(filepath)
      output = File.open(encrypted_filepath(filepath), 'w+')
      gpg_encrypter.encrypt input, recipients: SECRETS.concur_recipient, output: output, always_trust: true
    end

    def generate_lists
      generate_location_list
      generate_department_list
    end

    def generate_location_list
      List.new.location_list
    end

    def generate_department_list
      List.new.department_list
    end

    def generate_employee_import(upload_group)
      EnhancedEmployee.new.generate_csv(upload_group)
    end

    def encrypted_filepath(filepath)
      Pathname.new(filepath).to_path + '.gpg'
    end

    def encrypted_files
      encrypted = []
      all_filepaths.map { |file| encrypted << file if file.include? '.gpg' }
      encrypted
    end

    def encrypt_all
      all_filepaths.each do |filepath|
        encrypt(filepath)
      end
    end

    def all_filepaths
      Dir['tmp/concur/*'].map { |filepath| filepath }
    end

    def gpg_encrypter
      pub_key_path = Pathname.new(SECRETS.concur_public_key_path)
      pub_key = File.open(pub_key_path)
      GPGME::Key.import(pub_key)
      GPGME::Crypto.new armor: true
    end

    def remote_filepath(local_filepath)
      local = Pathname.new(local_filepath)
      remote = Pathname.new('/in') + local.basename
      remote.to_path
    end

    def password
      SECRETS.concur_sftp_pass
    end

    def port
      SECRETS.concur_sftp_port
    end

    def uri
      URI.parse("sftp://#{SECRETS.concur_sftp_host}")
    end

    # Daily upload regular employees who meet one of the following:
    # - started today
    # - info changed in last 24 hours
    # - terminated yesterday
    def daily_upload
      EmployeeQuery.new.concur_upload_group
    end

    # Mezzo only uploads regular employees to Concur.
    # One-time upload of all workers.
    # Contractors or temp workers needing Concur access
    # must have accounts manually created by Finance.
    def initial_upload
      EmployeeQuery.new.active_regular_workers
    end

    def verify_directory
      dirname = 'tmp/concur'
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

      Dir["#{dirname}/*"].each do |f|
        File.delete(f)
      end
    end
  end
end
