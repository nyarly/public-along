require 'spreadsheet'

module Report
  module Onboard
    class Daily
      def initialize
        @dirname = "tmp/reports/onboard"
        @name = "daily"
        @date = DateTime.now.strftime('%Y%m%d')

        prepare_directory

        @book = Spreadsheet::Workbook.new
        @sheet = @book.create_worksheet(name: @name)

        call
      end

      private

      def call
        add_headers
        populate_rows
        highlight_new_changes
        write_to_file
      end

      def prepare_directory
        Dir["#{@dirname}/*"].each do |f|
          File.delete(f)
        end

        unless File.directory?(@dirname)
          FileUtils.mkdir_p(@dirname)
        end
      end

      def filename
        @dirname + "/" + @name + "_" + @date + ".xls"
      end

      def onboarding_workers
        OnboardQuery.new(:onboarding).all
      end

      def add_headers
        @sheet.row(0).concat(%w{ParentOrg Department Name EmployeeID EmployeeType Position Manager WorkLocation OnboardingFormDueOn OnboardingFormSubmittedOn Email BuddyName BuddyEmail StartDate ContractEndDate LastModifiedAt })
      end

      def populate_rows
        onboarding_workers.each_with_index do |profile, idx|
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
            employee.onboarding_due_date,        # string field
            onboard_submitted_on(employee),      # date field
            employee.email,
            employee.buddy.try(:cn),
            employee.buddy.try(:email),
            employee.current_profile.start_date, # date field
            employee.contract_end_date,          # date field
            employee.last_changed_at             # date field
          ]
          @sheet.insert_row(row_num, values)
        end
      end

      def write_to_file
        @book.write(filename)
      end

      def highlight_new_changes
        highlight = Spreadsheet::Format.new(pattern_fg_color: :yellow, pattern: 1)

        @sheet.rows.each_with_index do |row, idx|
          last_changed = row[15]
          if last_changed >= summary_last_sent
            @sheet.row(idx).default_format = highlight
          end unless idx == 0
        end
      end

      def summary_last_sent
        # cwday returns the day of calendar week (1-7, Monday is 1).
        3.days.ago if Date.today.cwday == 1
        1.day.ago
      end

      def onboard_submitted_on(employee)
        return nil if employee.request_status == "waiting"
        onboards = employee.emp_transactions.where(kind: "Onboarding")
        return nil if onboards.blank?
        onboards.last.created_at.to_datetime
      end
    end
  end
end
