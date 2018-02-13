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

      # HACK: Public method for testing cell formats.
      # Xlsx formatting cannot be read by any known library.
      def cell_format(worker, idx)
        return highlighted_cell_format(idx) if changed_since_last_sent?(worker.last_changed_at)
        regular_cell_format(idx)
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
                          'Buddy',
                          'Buddy Email',
                          'Start Date',
                          'Contract End Date',
                          'Last Modified'
                        ],
            style: header_format)

          onboarding_workers.each do |profile|
            worker = profile.employee
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
                            worker.buddy.try(:cn),
                            worker.buddy.try(:email),
                            worker.current_profile.start_date,
                            worker.contract_end_date,
                            worker.last_changed_at
                          ],
              style: [
                cell_format(worker, 0),
                cell_format(worker, 1),
                cell_format(worker, 2),
                cell_format(worker, 3),
                cell_format(worker, 4),
                cell_format(worker, 5),
                cell_format(worker, 6),
                cell_format(worker, 7),
                cell_format(worker, 8),
                cell_format(worker, 9),
                cell_format(worker, 10),
                cell_format(worker, 11),
                cell_format(worker, 12),
                cell_format(worker, 13),
                cell_format(worker, 14),
                cell_format(worker, 15)
              ])
          end
        end
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

      def regular_cell_format(idx)
        return date_format if short_date?(idx)
        return date_time_format if long_date?(idx)
        nil
      end

      def highlighted_cell_format(idx)
        return highlight_short_date if short_date?(idx)
        return highlight_long_date if long_date?(idx)
        highlight
      end

      def changed_since_last_sent?(last_changed_datetime)
        last_changed_datetime >= summary_last_sent_datetime
      end

      def short_date?(column_idx)
        [8, 13, 14].include? column_idx
      end

      def long_date?(column_idx)
        [9, 15].include? column_idx
      end

      def summary_last_sent_datetime
        # cwday returns the day of calendar week (1-7, Monday is 1).
        3.days.ago if Date.today.cwday == 1
        1.day.ago
      end

      def onboard_submitted_on(employee)
        return nil if employee.waiting?
        onboards = employee.emp_transactions.where(kind: 'Onboarding')
        return nil if onboards.blank?
        onboards.last.created_at.to_datetime
      end
    end
  end
end
