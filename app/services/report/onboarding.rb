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
      book.add_format(Spreadsheet::Format.new(number_format: 'DD.MM.YYY hh:mm:ss'))
      sheet = book.create_worksheet(name: 'Onboards')

      sheet.row(0).concat %w{ParentOrg Department Name EmployeeID EmployeeType Position Manager WorkLocation OnboardingFormDueOn OnboardingFormSubmittedOn Email BuddyName BuddyEmail StartDate ContractEndDate LastModifiedAt }

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
          employee.onboarding_due_date,                                     # date field
          onboard_submitted_on(employee),                                   # date field
          employee.email,
          buddy(employee).try(:cn),
          buddy(employee).try(:email),
          employee.current_profile.start_date,  # date field
          employee.contract_end_date,           # date field
          employee.last_changed_at                # date field
        ]

        sheet.insert_row(row_num, values)
        format_date_cells(sheet.rows[row_num])
      end

      # highlight_new_changes(sheet)
      book.write(file_name)
    end

    private

    def format_date_cells(row)
      date_field_cells = [8, 9, 13, 14, 15]

      date_field_cells.each do |cell_idx|
        row[cell_idx].formats.number_format = 'DD.MM.YYY hh:mm:ss'
      end
    end

    def highlight_new_changes(sheet)
      highlight = Spreadsheet::Format.new(pattern_fg_color: :yellow, pattern: 1)

      sheet.rows.each do |row|
        last_changed = row[15]
        if last_changed >= summary_last_sent
          sheet.row(row_num).default_format = highlight
        end
      end
    end

    def summary_last_sent
      # cwday returns the day of calendar week (1-7, Monday is 1).
      3.days.ago if Date.today.cwday == 1
      1.day.ago
    end

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
      onboards.last.created_at
    end

  end
end
