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
        "Start Date",
        "Contract End Date",
        "Employee Info Last Modified"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        Employee.onboarding_report_group.each do |employee|
          csv << [
            employee.cn,
            employee.employee_id,
            employee.worker_type.try(:name),
            employee.job_title.try(:name),
            employee.department.name,
            employee.manager.try(:cn),
            employee.location.name,
            employee.onboarding_due_date,
            employee.onboarding_complete?,
            employee.email,
            buddy(employee).try(:cn),
            buddy(employee).try(:email),
            employee.hire_date.strftime("%b %e, %Y"),
            employee.contract_end_date.try(:strftime, "%b %e, %Y"),
            last_changed(employee).try(:strftime, "%b %e, %Y at %H:%M:%S")
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
            employee.offboarding_complete?,
            last_changed(employee).try(:strftime, "%b %e, %Y at %H:%M:%S")
          ]
        end
      end
    end

    def job_change_data
      attrs = [
        "Name",
        "Prior Values",
        "Current Values",
        "Changed At"
      ]
      CSV.generate(headers: true) do |csv|
        csv << attrs

        EmpDelta.report_group.each do |delta|
          csv << [
            delta.employee.cn,
            delta.format(delta.before),
            delta.format(delta.after),
            delta.created_at.strftime("%b %e, %Y at %H:%M:%S")
          ]
        end
      end
    end

    def last_changed(employee)

      # looking for last meaningful change to employee record,
      # which may include changes to offboarding or onboarding info.
      # this function will return the most recent change.
      # if for some reason there are no changes to the record, it will return the created_at date
      # this is a workaround as the sync updates the record every hour.

      changed = []

      deltas = EmpDelta.where("employee_id = ? AND before != '' AND after != ''", employee.id)
      onboards = employee.onboarding_infos
      offboards = employee.offboarding_infos

      if deltas.present?
        changed << deltas.order('created_at ASC').last.created_at
      end

      if onboards.present?
        changed << onboards.order('created_at ASC').last.created_at
      end

      if offboards.present?
        changed << offboards.order('created_at ASC').last.created_at
      end

      if changed.present?
        changed.sort.last
      else
        employee.created_at
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
