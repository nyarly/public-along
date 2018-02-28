module ConcurImporter
  # Employee record parser for enhanced employee import
  class EmployeeDetail
    attr_reader :employee

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
      employee.active? ? "Y" : "N"
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
      work_location.code
    end

    def group_name_code
      return "UK" if country_code == "GB"
      return country_code if CONCUR_GROUP_NAMES.include?(country_code)
      "US"
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

    def invoice_approver
      approver_id
    end

    def bi_manager
      approver_id
    end

    def approver_status
      profile.management_position ? "Y" : "N"
    end

    def reimbursement_method_code
      return "ADPPAYR" if country_code == "US"
      return "APCHECK" if country_code == "CA"
      "CNQRPAY"
    end

    def adp_company_code
      adp_reimbursed? ? "WP8" : nil
    end

    def adp_deduction_code
      adp_reimbursed? ? "E" : nil
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

    def currency
      work_country.currency
    end

    def adp_reimbursed?
      reimbursement_method_code == "ADPPAYR"
    end
  end
end
