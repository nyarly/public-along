require 'csv'

module SummaryReportHelper
  class Csv

    def offboarding_data
      attrs = [
        'Name',
        'Employee ID',
        'Worker Type',
        'Position',
        'Department',
        'Manager',
        'Work Location',
        'Email',
        'Transfer Salesforce Cases',
        'Start Date',
        'Termination Date',
        'Contract End Date',
        'Offboarding Form Submitted',
        'Offboarded At',
        'Worker Info Last Modified'
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        OffboardQuery.new.report_group.each do |profile|
          employee = profile.employee

          csv << [
            employee.cn,
            employee.employee_id,
            employee.worker_type.try(:name),
            employee.job_title.try(:name),
            employee.department.name,
            employee.manager.cn,
            employee.location.name,
            employee.email,
            salesforce(employee).try(:cn),
            employee.hire_date.strftime('%Y-%b-%e'),
            employee.termination_date.try(:strftime, '%Y-%b-%e'),
            employee.contract_end_date.try(:strftime, '%Y-%b-%e'),
            offboard_form_status(employee),
            employee.offboarded_at.try(:strftime, '%Y-%b-%e'),
            employee.last_changed_at.try(:strftime, '%Y-%m-%d %H:%M:%S')
          ]
        end
      end
    end


    def job_change_data
      attrs = [
        "Parent Department",
        "Department",
        "First Name",
        "Last Name",
        "Employee ID",
        "ADP Job Title",
        "Manager Full Name",
        "Location",
        "Start Date",
        "Change Type",
        "Old Value",
        "New Value",
        "Change Time Stamp"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        EmpDelta.report_group.each do |delta|
          changes = delta.format_by_key
          employee = delta.employee

          changes.each do |change|
            csv << [
              employee.department.parent_org.try(:name),
              employee.department.try(:name),
              employee.first_name,
              employee.last_name,
              employee.current_profile.adp_employee_id,
              employee.job_title.try(:name),
              employee.manager.try(:cn),
              employee.location.try(:name),
              employee.current_profile.start_date.strftime("%Y-%m-%d"),
              change["name"],
              change["before"],
              change["after"],
              delta.created_at.try(:strftime, "%Y-%m-%d %H:%M:%S"),
            ]
          end
        end
      end
    end

    private

    def offboard_form_status(employee)
      info = offboarding_info(employee)
      info.present? ? info.created_at.strftime('%Y-%m-%d %H:%M:%S') : employee.request_status
    end

    def salesforce(employee)
      return nil if employee.offboarding_infos.empty?
      emp_id =  offboarding_info(employee).try(:reassign_salesforce_id)
      transfer_to = Employee.find(emp_id)
      return nil if transfer_to.blank?
      transfer_to
    end

    def offboarding_info(employee)
      employee.offboarding_infos.present? ? employee.offboarding_infos.last : nil
    end
  end
end
