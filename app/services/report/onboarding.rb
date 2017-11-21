require 'spreadsheet'

module Report
  class Onboarding

    def create
      dirname = "tmp/reports"
      file_name = dirname + "/onboarding_" + DateTime.now.strftime('%Y%m%d') + ".xls"

      Dir["tmp/reports/*"].each do |f|
        File.delete(f)
      end

      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end

      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet(name: 'Onboards')

      sheet.row(0).concat %w{ParentOrg Department Name EmployeeID EmployeeType Position Manager WorkLocation OnboardingFormDueOn OnboardingFormSubmittedOn Email BuddyName BuddyEmail StartDate ContractEndDate LastModified }

      sorted = Profile.includes([:department, department: :parent_org]).onboarding_report_group.sort_by{ |e| [e.department.parent_org.name, e.department.name] }

      sorted.each_with_index do |profile, idx|
        employee = profile.employee
        row_num = idx + 1

        values = [
          employee.department.parent_org.try(:name),
          employee.department.try(:name),
          employee.cn,
          employee.current_profile.adp_employee_id,
          employee.worker_type.try(:name),
          employee.job_title.try(:name),
          employee.manager.try(:cn),
          employee.location.try(:name),
          employee.onboarding_due_date,
          onboard_submitted_on(employee),
          employee.email,
          buddy(employee).try(:cn),
          buddy(employee).try(:email),
          employee.current_profile.start_date.try(:strftime, "%b %e, %Y"),
          employee.contract_end_date.try(:strftime, "%b %e, %Y"),
          employee.last_changed_at.try(:strftime, "%b %e, %Y at %H:%M:%S")
        ]

        sheet.insert_row(row_num, values)
      end

      book.write(file_name)
    end

    private

    def buddy(employee)
      return nil if employee.onboarding_infos.blank?
      return nil if employee.onboarding_infos.last.buddy_id.blank?

      buddy_id = employee.onboarding_infos.last.buddy_id
      buddy = Employee.find(buddy_id)

      return buddy if buddy.present?
    end

    def onboard_submitted_on(employee)
      return nil if employee.request_status == "waiting"
      onboards = employee.emp_transactions.where(kind: "Onboarding")
      return nil if onboards.blank?
      onboards.last.created_at.try(:strftime, "%b %e, %Y at %H:%M:%S")
    end

  end
end
