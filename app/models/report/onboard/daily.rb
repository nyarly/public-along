require 'axlsx'

# Creates xlsx formatted report of onboards for daily send.
# Highlights changes since report last sent.
module Report
  module Onboard
    class Daily
      attr_reader :dirname
      attr_reader :filename
      attr_reader :workbook

      def initialize
        package = Axlsx::Package.new
        @dirname = 'tmp/reports/onboard'
        @filename = 'daily'
        @workbook = package.workbook

        prepare_files
        generate_worksheet
        package.serialize(filepath)
      end

      # HACK: Can't inspect styles in tests
      # Public method so test can access formats
      def worker_row_styles(worker)
        return new_onboard_styles if changed_since_last_sent?(worker.last_changed_at)
        onboard_styles
      end

      private

      def prepare_files
        check_directory
        clear_reports
      end

      def check_directory
        return true if File.directory?(dirname)
        FileUtils.mkdir_p(@dirname)
      end

      def clear_reports
        Dir["#{dirname}/*"].each do |f|
          File.delete(f)
        end
      end

      def filepath
        "#{dirname}/#{filename}_#{Time.now.strftime('%Y%m%d')}.xlsx"
      end

      def onboarding_workers
        OnboardQuery.new.onboarding
      end

      def generate_worksheet
        workbook.add_worksheet(name: 'daily') do |sheet|
          add_headers(sheet)
          add_worksheet_styles

          onboarding_workers.each do |profile|
            add_worker_row(sheet, profile.employee)
          end
        end
      end

      def add_worker_row(sheet, worker)
        sheet.add_row([
                worker.department.parent_org.try(:name),
                worker.department.try(:name),
                worker.cn,
                worker.current_profile.adp_employee_id,
                worker.worker_type.try(:name),
                worker.job_title.try(:name),
                worker.manager.try(:cn),
                worker.location.try(:name),
                worker.onboarding_due_date,
                onboard_submitted_on(worker),
                worker.email,
                worker.sam_account_name,
                worker.buddy.try(:cn),
                worker.buddy.try(:email),
                worker.current_profile.start_date,
                worker.contract_end_date,
                worker.last_changed_at
              ],
          style: worker_row_styles(worker) )
      end

      def add_headers(sheet)
        sheet.add_row([
                'Parent Org',
                'Department',
                'Name',
                'Employee ID',
                'Employee Type',
                'Position',
                'Manager',
                'Location',
                'Onboarding Form Due',
                'Onboarding Form Submitted',
                'Email',
                'Username',
                'Buddy',
                'Buddy Email',
                'Start Date',
                'Contract End Date',
                'Last Modified'
              ],
          style: header_format)
      end

      def add_worksheet_styles
        highlight_short_date
        highlight_long_date
        highlight
        date_format
        date_time_format
      end

      def new_onboard_styles
        [6, 6, 6, 6, 6, 6, 6, 6, 4, 5, 6, 6, 6, 6, 4, 4, 5]
      end

      def onboard_styles
        [nil, nil, nil, nil, nil, nil, nil, nil, 7, 8, nil, nil, nil, nil, 7, 7, 8]
      end

      def header_format
        workbook.styles.add_style(bg_color: '000000', fg_color: 'FFFFFF', b: true)
      end

      def date_format
        workbook.styles.add_style(format_code: 'yyyy-mm-dd')
      end

      def date_time_format
        workbook.styles.add_style(format_code: 'yyyy-mm-dd hh:mm')
      end

      def highlight
        workbook.styles.add_style(bg_color: 'FFFF00', pattern: 1)
      end

      def highlight_short_date
        workbook.styles.add_style(bg_color: 'FFFF00', pattern: 1, format_code: 'yyyy-mm-dd')
      end

      def highlight_long_date
        workbook.styles.add_style(bg_color: 'FFFF00', pattern: 1, format_code: 'yyyy-mm-dd hh:mm')
      end

      def changed_since_last_sent?(last_changed_datetime)
        last_changed_datetime >= summary_last_sent_datetime
      end

      def summary_last_sent_datetime
        # cwday returns the day of calendar week (1-7, Monday is 1).
        3.days.ago if Date.today.cwday == 1
        1.day.ago
      end

      def onboard_submitted_on(employee)
        return nil if employee.waiting?
        onboards = employee.emp_transactions.where(kind: 'onboarding')
        return nil if onboards.blank?
        onboards.last.created_at.to_datetime
      end
    end
  end
end
