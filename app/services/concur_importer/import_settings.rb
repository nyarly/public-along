module ConcurImporter
  class ImportSettings

    # Import Settings, Record Type 100
    # Record ID: ImportSettings
    def generate_csv

      # All fields are required
      CSV.open(file_name, 'w+:bom|utf-8') do |csv|
        csv << [
          '100',      # Transaction Type: Static numeric value always equal to 100
          '0',        # Error Threshold: Deprecated but required, int >= 0
          'SSO',      # Password Generation: Single Sign On
          'UPDATE',   # Existing Record Handling: Updates existing records with ONLY fields that are nonblank in import file
          'en_US',    # Language Code
          'Y',        # Validate Expense Group
          'Y'         # Validate Payment Group
        ]
      end
    end

    private

    def file_name
      "tmp/concur/import_settings_#{SECRETS.concur_entity_code}_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt"
    end
  end
end
