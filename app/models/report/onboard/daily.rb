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
        format_rows
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
        OnboardQuery.new.onboarding
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
            employee.onboarding_due_date,        # date field
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

      def format_rows
        @sheet.rows.each_with_index do |row, idx|
          format_row(row) unless is_header?(idx)
        end
      end

      def format_row(row)
        return assign_highlighted_formats(row) if changed_since_last_sent?(row[15])
        assign_regular_formats(row)
      end

      def assign_regular_formats(row)
        row.enum_for(:each_with_index).map { |cell_val, idx| row.set_format(idx, regular_cell_format(idx)) }
      end

      def assign_highlighted_formats(row)
        row.enum_for(:each_with_index).map { |cell_val, idx| row.set_format(idx, highlighted_cell_format(idx)) }
      end

      def regular_cell_format(idx)
        date_time_format = Spreadsheet::Format.new(number_format: 'YYYY-MM-DD hh:mm:ss')
        date_format = Spreadsheet::Format.new(number_format: 'YYYY-MM-DD')

        return date_format if is_short_date?(idx)
        return date_time_format if is_long_date?(idx)
        nil
      end

      def highlighted_cell_format(idx)
        highlight_short_date = Spreadsheet::Format.new(pattern_fg_color: :yellow, pattern: 1, number_format: 'YYYY-MM-DD')
        highlight_long_date = Spreadsheet::Format.new(pattern_fg_color: :yellow, pattern: 1, number_format: 'YYYY-MM-DD hh:mm:ss')
        highlight = Spreadsheet::Format.new(pattern_fg_color: :yellow, pattern: 1)

        return highlight_short_date if is_short_date?(idx)
        return highlight_long_date if is_long_date?(idx)
        highlight
      end

      def is_header?(row_idx)
        row_idx == 0
      end

      def changed_since_last_sent?(last_changed_datetime)
        last_changed_datetime >= summary_last_sent_datetime
      end

      def is_short_date?(column_idx)
        [8, 13, 14].include? column_idx
      end

      def is_long_date?(column_idx)
        [9, 15].include? column_idx
      end

      def summary_last_sent_datetime
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
