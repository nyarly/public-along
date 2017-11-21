require 'csv'

module SummaryReportHelper
  class Csv

    def offboarding_data
      attrs = [
        "Name",
        "Employee ID",
        "Employee Type",
        "Position",
        "Department",
        "Manager",
        "Work Location",
        "Email",
        "Transfer SalesForces Cases to",
        "Start Date",
        "Termination Date",
        "Offboarding Form Submitted",
        "Employee Info Last Modified"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        Employee.offboarding_report_group.each do |employee|
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
            employee.hire_date.strftime("%b %e, %Y"),
            employee.termination_date.strftime("%b %e, %Y"),
            employee.request_status,
            employee.last_changed_at.try(:strftime, "%b %e, %Y at %H:%M:%S")
          ]
        end
      end
    end

    def job_change_data
      attrs = [
        "Employee ID",
        "First Name",
        "Last Name",
        "Job Title",
        "Manager Full Name",
        "Department",
        "Location",
        "Start Date",
        "Change Type",
        "Old Value",
        "New Value",
        "Changed At",
        "Worker Type"
      ]

      CSV.generate(headers: true) do |csv|
        csv << attrs

        EmpDelta.report_group.each do |delta|
          changes = delta.format_by_key
          created_at = delta.created_at
          start_date = delta.employee.current_profile.start_date

          changes.each do |change|
            csv << [
              delta.employee.current_profile.adp_employee_id,
              delta.employee.first_name,
              delta.employee.last_name,
              delta.employee.job_title.try(:name),
              delta.employee.manager.try(:cn),
              delta.employee.department.try(:name),
              delta.employee.location.try(:name),
              start_date,
              change["name"].titleize,
              change["before"],
              change["after"],
              created_at,
              delta.employee.worker_type.name
            ]
          end
        end
      end
    end

    def salesforce(employee)
      if employee.offboarding_infos.count > 0
        emp_id =  employee.offboarding_infos.last.reassign_salesforce_id
        Employee.find(emp_id)
      else
        nil
      end
    end
  end
end
