module ConcurImporter
  # Employee record parser for enhanced employee import
  class EmployeeDetail
    attr_reader :employee
    attr_reader :info

    def initialize(employee)
      @employee = employee
      @info ||= {}
    end

    def all
      worker_info
      location_info
      approver_info
      reimbursement_info
      info
    end

    private

    def worker_info
      info[:first_name] = employee.first_name
      info[:last_name] = employee.last_name
      info[:employee_id] = employee_id
      info[:email] = employee.email
      info[:status] = active?
      info[:department_code] = department.code
    end

    def location_info
      info[:country_code] = work_country_code
      info[:currency_code] = currency.code
      info[:company] = profile.company
      info[:location_code] = work_location.code
      info[:group_name] = group_name
    end

    def approver_info
      info[:expense_report_approver] = approver_id
      info[:cash_advance_approver] = approver_id
      info[:request_approver] = approver_id
      info[:invoice_approver] = approver_id
      info[:bi_manager] = approver_id
      info[:approver_status] = request_approver?
    end

    def reimbursement_info
      info[:reimbursement_method_code] = reimbursement_code
      info[:adp_file_number] = file_number
      info[:adp_company_code] = adp_company_code
      info[:adp_deduction_code] = adp_deduction_code
    end

    def approver_id
      approver.present? ? approver.current_profile.adp_employee_id : nil
    end

    def approver
      employee.manager.present? ? employee.manager : nil
    end

    def profile
      employee.current_profile
    end

    def employee_id
      profile.adp_employee_id
    end

    def work_location
      profile.location
    end

    def work_country
      work_location.try(:address).country
    end

    def work_country_code
      work_country.code || 'US'
    end

    def work_country_name
      work_country.name
    end

    def currency
      work_country.currency
    end

    def active?
      employee.active? ? 'Y' : 'N'
    end

    def department
      profile.department
    end

    def group_name
      return 'United Kingdom' if work_country_name == 'Great Britain'
      return work_country_name if CONCUR_GROUP_NAMES.include?(work_country_name)
      'United States'
    end

    def request_approver?
      profile.management_position ? 'Y' : 'N'
    end

    def adp_reimbursed?
      reimbursement_code == 'ADPPAYR'
    end

    def reimbursement_code
      return 'ADPPAYR' if work_country_name == 'United States'
      return 'APCHECK' if work_country_name == 'Canada'
      'CNQRPAY'
    end

    def file_number
      file_num = employee.payroll_file_number
      return file_num if adp_reimbursed? && file_num.present?
      return employee_id if adp_reimbursed?
      nil
    end

    def adp_company_code
      adp_reimbursed? ? 'WP8' : nil
    end

    def adp_deduction_code
      adp_reimbursed? ? 'E' : nil
    end
  end
end
