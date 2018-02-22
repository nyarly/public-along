module ConcurImporter
  # Employee record parser for enhanced employee import
  class EmployeeDetail
    attr_reader :employee
    attr_reader :info

    def initialize(employee)
      @employee = employee
    end

    def first_name
      employee.first_name
    end

    def last_name
      employee.last_name
    end

    def employee_id
      profile.adp_employee_id
    end

    def email
      employee.email
    end

    def status
      employee.active? ? 'Y' : 'N'
    end

    def department_code
      profile.department.code
    end

    def country_code
      work_country.iso_alpha_2_code
    end

    def currency_code
      currency.iso_alpha_code
    end

    def company
      profile.company
    end

    def location_code
      work_locaiton.code
    end

    def group_name
      return 'United Kingdom' if work_country_name == 'Great Britain'
      return work_country_name if CONCUR_GROUP_NAMES.include?(work_country_name)
      'United States'
    end

    def expense_report_approver
      approver_id
    end

    def cash_advance_approver
      approver_id
    end

    def request_approver
      approver_id
    end

    def bi_manager
      approver_id
    end

    def approver_status
      profile.management_position ? 'Y' : 'N'
    end

    def reimbursement_method_code
      return 'ADPPAYR' if work_country_name == 'United States'
      return 'APCHECK' if work_country_name == 'Canada'
      'CNQRPAY'
    end

    def adp_company_code
      adp_reimbursed? ? 'WP8' : nil
    end

    def adp_deduction_code
      adp_reimbursed? ? 'E' : nil
    end

    def adp_file_number
      file_num = employee.payroll_file_number
      return file_num if adp_reimbursed? && file_num.present?
      return employee_id if adp_reimbursed?
      nil
    end

    private

    def approver_id
      approver.present? ? approver.current_profile.adp_employee_id : nil
    end

    def approver
      employee.manager.present? ? employee.manager : nil
    end

    def profile
      employee.current_profile
    end

    def work_location
      profile.location
    end

    def work_country
      work_location.try(:address).country
    end

    def work_country_name
      work_country.name
    end

    def currency
      work_country.currency
    end

    def adp_reimbursed?
      reimbursement_code == 'ADPPAYR'
    end
  end
end
