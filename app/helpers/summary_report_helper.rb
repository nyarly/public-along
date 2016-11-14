require 'csv'

module SummaryReportHelper
  class Csv
    def onboarding_data
      attrs = [
        "Name",
        "Employee ID",
        "Employee Type",
        "Position",
        "Department",
        "Manager",
        "Work Location",
        "Onboarding Form Due Date",
        "Onboarding Form Submitted",
        "Email",
        "Buddy Name",
        "Buddy Email",
        "Start Date"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        Employee.onboarding_report_group.each do |employee|
          csv << [
            employee.cn,
            employee.employee_id,
            employee.employee_type,
            employee.business_title,
            employee.department.name,
            employee.manager.try(:cn),
            employee.location.name,
            employee.onboarding_due_date,
            employee.onboarding_complete?,
            employee.email,
            buddy(employee).try(:cn),
            buddy(employee).try(:email),
            employee.hire_date.strftime("%b %e, %Y")
          ]
        end
      end
    end

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
        "Termination Date"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        Employee.offboarding_report_group.each do |employee|
          csv << [
            employee.cn,
            employee.employee_id,
            employee.employee_type,
            employee.business_title,
            employee.department.name,
            employee.manager.cn,
            employee.location.name,
            employee.email,
            salesforce(employee).try(:cn),
            employee.hire_date.strftime("%b %e, %Y"),
            employee.termination_date.strftime("%b %e, %Y"),
          ]
        end
      end
    end

    def job_change_data
      attrs = [
        "Name",
        "Prior Values",
        "Current Values"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        EmpDelta.report_group.each do |delta|
          csv << [
            delta.employee.cn,
            delta.format(delta.before),
            delta.format(delta.after)
          ]
        end
      end
    end

    def buddy(employee)
      emp_trans = employee.emp_transactions.where(kind: "Onboarding").last
      if emp_trans
        buddy_id =  emp_trans.onboarding_infos.last.buddy_id
        Employee.find(buddy_id) if buddy_id
      else
        nil
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
