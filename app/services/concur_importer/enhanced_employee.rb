module ConcurImporter
  # Record Type 305
  # Record ID: EnhancedEmployeeImporter
  class EnhancedEmployee

    def generate_csv(employee_group)
      employees = employee_group

      CSV.open(file_name, 'w+:bom|utf-8', force_quotes: false) do |csv|
        csv << [
          100,
          0,
          'SSO',
          'UPDATE',
          'EN',
          'N',
          'N'
        ]

        employees.each do |employee|
          worker_data = EmployeeDetail.new(employee)

          # Fields marked by * are required
          csv << [
            305,                                    # 01: * Transaction Type: Static numeric value
            worker_data.first_name,                 # 02: * First name
            nil,                                    # 03:   Middle name
            worker_data.last_name,                  # 04: * Last name
            worker_data.employee_id,                # 05: * Employee ID
            worker_data.email,                      # 06: * Login ID, format like employee@domain
            nil,                                    # 07:   Password
            worker_data.email,                      # 08: * Email address, lowercase
            'en_US',                                # 09: * Locale code
            worker_data.country_code,               # 10:   Country code
            nil,                                    # 11:   Country sub code
            'DEFAULT',                              # 12: * Ledger code
            worker_data.currency_code,              # 13: * Reimbursement currency code
            nil,                                    # 14:   Cash advance account code
            worker_data.status,                     # 15: * Active, Y or N
            nil,                                    # 16:   Fields 16 - 21 are Organizational Units 1-6
            nil,                                    # 17:
            nil,                                    # 18:
            nil,                                    # 19:
            nil,                                    # 20:
            nil,                                    # 21:
            worker_data.company,                    # 22:   Custom 1: Company
            nil,                                    # 23:   Custom 2: Month of Service
            nil,                                    # 24:   Custom 3: DE Employees
            nil,                                    # 25:   Custom 4:
            nil,                                    # 26:   Custom 5:
            nil,                                    # 27:   Custom 6:
            nil,                                    # 28:   Custom 7:
            nil,                                    # 29:   Custom 8:
            nil,                                    # 30:   Custom 9:
            worker_data.department_code,            # 31:   Custom 10: Department (from department list upload)
            worker_data.location_code,              # 32:   Custom 11: Location (from location list upload)
            0,                                      # 33:   Custom 12: Cell Phone Limit
            worker_data.employee_id,                # 34:   Custom 13: Traveler Profile ID (Employee ID)
            nil,                                    # 35:   Custom 14: Customer   # / Restaurant
            nil,                                    # 36:   Custom 15:
            nil,                                    # 37:   Custom 16:
            nil,                                    # 38:   Custom 17:
            nil,                                    # 39:   Custom 18:
            nil,                                    # 40:   Custom 19:
            nil,                                    # 41:   Custom 20:
            worker_data.group_name_code,            # 42:   Custom 21: Employee Group
            nil,                                    # 43:   Fields 43 - 58 are Employee Workflow Preferences
            nil,                                    # 44:
            nil,                                    # 45:
            nil,                                    # 46:
            nil,                                    # 47:
            nil,                                    # 48:
            nil,                                    # 49:
            nil,                                    # 50:
            nil,                                    # 51:
            nil,                                    # 52:
            nil,                                    # 53:
            nil,                                    # 54:
            nil,                                    # 55:
            nil,                                    # 56:
            nil,                                    # 57:
            nil,                                    # 58:
            worker_data.expense_report_approver,    # 59:   Employee ID of Expense Report Approver
            nil,                                    # 60:   Employee ID of Cash Advance Approver
            nil,                                    # 61:   Employee ID of Request Approver
            nil,                                    # 62:   Employee ID of Invoice Approver
            nil,                                    # 63:   Expense User (default change of value from assigned roles)
            worker_data.expense_approver_status,    # 64:   Expense and/or Cash Advance Approver
            nil,                                    # 65:   Company Card Administrator
            nil,                                    # 66:   --
            nil,                                    # 67:   Receipt Processor
            nil,                                    # 68:   --
            nil,                                    # 69:   Import/Extract Monitor
            nil,                                    # 70:   Company Info Administrator
            nil,                                    # 71:   Offline User
            nil,                                    # 72:   Reporting Configuration Administrator
            nil,                                    # 73:   Invoice User
            nil,                                    # 74:   Invoice Approver
            nil,                                    # 75:   Invoice Vendor Manager
            nil,                                    # 76:   Expense Audit Required: 'REQ', 'ALW', 'NVR'
            worker_data.bi_manager,                 # 77:   BI Manager Employee ID
            nil,                                    # 78:   Request User Y or N
            nil,                                    # 79:   Request Approver y or n
            nil,                                    # 80:   Expense Report Approver Employee ID 2
            nil,                                    # 81:   A Payment Request has been Assigned
            nil,                                    # 82:   --
            nil,                                    # 83:   --
            nil,                                    # 84:   Tax Administrator
            nil,                                    # 85:   FBT Administrator
            'Y',                                    # 86:   Travel Wizard User
            worker_data.group_name_code,            # 87:   Custom field: Group Name
            nil,                                    # 88:   Request Approver Employee ID 2
            nil,                                    # 89:   Is Non-employee, blank == N
            worker_data.reimbursement_method_code,  # 90:   Reimbursement Type: 'ADPPAYR', 'CNQRPAY', 'APCHECK', 'PMTSERV'
            worker_data.adp_file_number,            # 91:   ADP Employee File Number, required if reimbursement type is ADPPAYR
            worker_data.adp_company_code,           # 92:   ADP Company Code
            worker_data.adp_deduction_code,         # 93:   ADP Deduction Code
            nil,                                    # 94:   Budget Manager Employee ID
            nil,                                    # 95:   Budget Owner
            nil,                                    # 96:   Budget Viewer
            nil,                                    # 97:   Budget Approver
            nil,                                    # 98:   Budget Admin
            nil,                                    # 99:   -- 99 - 137 reserved for future use
            nil,                                    # 100:  --
            nil,                                    # 101:  --
            nil,                                    # 102:  --
            nil,                                    # 103:  --
            nil,                                    # 104:  --
            nil,                                    # 105:  --
            nil,                                    # 106:  --
            nil,                                    # 107:  --
            nil,                                    # 108:  --
            nil,                                    # 109:  --
            nil,                                    # 110:  --
            nil,                                    # 111:  --
            nil,                                    # 112:  --
            nil,                                    # 113:  --
            nil,                                    # 114:  --
            nil,                                    # 115:  --
            nil,                                    # 116:  --
            nil,                                    # 117:  --
            nil,                                    # 118:  --
            nil,                                    # 119:  --
            nil,                                    # 120:  --
            nil,                                    # 121:  --
            nil,                                    # 122:  --
            nil,                                    # 123:  --
            nil,                                    # 124:  --
            nil,                                    # 125:  --
            nil,                                    # 126:  --
            nil,                                    # 127:  --
            nil,                                    # 128:  --
            nil,                                    # 129:  --
            nil,                                    # 130:  --
            nil,                                    # 131:  --
            nil,                                    # 132:  --
            nil,                                    # 133:  --
            nil,                                    # 134:  --
            nil,                                    # 135:  --
            nil,                                    # 136:  --
            nil                                     # 137:  --
          ]
        end
      end
    end

    private

    def file_name
      "tmp/concur/employee_#{SECRETS.concur_entity_code}_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt"
    end
  end
end
