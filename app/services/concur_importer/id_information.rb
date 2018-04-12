# Record Type 320 Import
# Update ID Information
# The only way to update a Concur user's employee id and/or login id.
# Must be uploaded one day prior to running 310 imports.
module ConcurImporter
  class IdInformation

    # Parses CSV into valid and invalid entry arrays
    # Expects row format to be ["firstname, lastname", concur_id, concur_login_id]
    def sort_entries(path)
      valid, invalid = valid_entries(path).partition { |entry| entry.length == 2 }
      [valid, invalid]
    end

    # Record type requires the current employee id from Concur for user to update.
    def generate_csv(id_pairs)
      CSV.open(file_name, 'w+:bom|utf-8') do |csv|
        csv << [
          100,
          0,
          'SSO',
          'UPDATE',
          'EN',
          'N',
          'N'
        ]
        id_pairs.each do |pair|
          split = pair.split(',')
          csv << [
            320,            # 01: * Transaction Type
            split[0].strip, # 02: * Current employee ID in Concur
            split[1].strip, # 03: * New employee ID
            nil,            # 04:   New Login ID, if replacing Login ID
            nil,            # 05:   Fields 5-9 reserved for future use
            nil,            # 06:
            nil,            # 07:
            nil,            # 08:
            nil,            # 09:
          ]
        end
      end
    end

    private

    def valid_entries(path)
      entries(path).map { |entry| entry_data(entry) }
    end

    def entry_data(entry)
      e = employee(entry[2].strip)
      return [entry[1].strip, employee_id(e)] if valid?(e, entry[0])
      entry
    end

    def entries(path)
      CSV.read(file(path))
    end

    def employee(login_id)
      Employee.find_by(email: login_id)
    end

    def employee_id(employee)
      employee.current_profile.adp_employee_id
    end

    def valid?(employee, employee_name)
      employee.present? && employee.fn == employee_name
    end

    def file(path)
      Pathname.new(path).to_path
    end

    def file_name
      "tmp/concur/employee_#{SECRETS.concur_entity_code}_idinformation_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt"
    end
  end
end
