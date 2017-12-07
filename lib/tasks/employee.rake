namespace :employee do
  desc "change status of employees (activate/deactivate)"
  task :change_status => :environment do
    full_terminations = []

    Employee.leave_return_group.each do |e|
      # Collect employees to activate on leave return date in their respective nearest time zone
      e.activate! if in_time_window?(e.leave_return_date, 3, e.nearest_time_zone)
    end

    Profile.onboarding_group.each do |p|
      # Collect employees to activate on position start date in their respective nearest time zone
      e = p.employee
      e.activate! if in_time_window?(p.start_date, 3, e.nearest_time_zone)
    end

    Employee.deactivation_group.each do |e|
      # Terminate workers between 9-10pm in their timezone on termination date
      if e.termination_date && in_time_window?(e.termination_date, 21, e.nearest_time_zone)
        e.terminate!

      # Terminate contractors between 9-10pm in their timezone on contract end date
      # These contractors were not given worker end dates in ADP
      # Send P&C request to terminate them
      elsif e.contract_end_date && in_time_window?(e.contract_end_date, 21, e.nearest_time_zone)
        e.terminate!
        PeopleAndCultureMailer.terminate_contract(e).deliver_now

      elsif e.leave_start_date && in_time_window?(e.leave_start_date - 1.day, 21, e.nearest_time_zone)
        e.start_leave!

      # Send techtable info for offboarding workers around noon
      elsif e.termination_date && in_time_window?(e.termination_date, 12, e.nearest_time_zone)
        TechTableMailer.offboard_instructions(e).deliver_now
      elsif e.contract_end_date && in_time_window?(e.termination_date, 12, e.nearest_time_zone)
        TechTableMailer.offboard_instructions(e).deliver_now
      end
    end

    Employee.full_termination_group.each do |e|
      if in_time_window?(e.termination_date + 7.days, 3, e.nearest_time_zone)
        full_terminations << e
      end
    end

    ads = ActiveDirectoryService.new
    ads.terminate(full_terminations)
  end

  desc "send onboarding reminders"
  task :send_onboarding_reminders => :environment do
    Employee.onboarding_reminder_group.each do |e|
      # send reminders at 9am local time day before onboarding due date
      if in_time_window?(e.onboarding_due_date.to_time - 1.day, 9, e.nearest_time_zone)
        ReminderWorker.perform_async(employee_id: e.id)
      end
    end
    AdpEvent.onboarding_reminder_group.each do |e|
      # same for unprocessed job change or rehire events
      profiler = EmployeeProfile.new
      employee = profiler.build_employee(e)
      if in_time_window?(employee.onboarding_due_date.to_time - 1.day, 9, employee.nearest_time_zone)
        ReminderWorker.perform_async(event_id: e.id)
      end
    end
  end

  desc "send contract end notifications"
  task :send_contract_end_notifications => :environment do
    contractors = EmployeeQuery.new.contract_end_reminder_group
    contractors.each do |e|
      if e.request_status == "none"
        e.wait!
        ContractorWorker.perform_async(employee_id: e.id)
      end
    end
  end
end

def in_time_window?(date, hour, zone)
  start_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, hour))
  end_time = ActiveSupport::TimeZone.new(zone).local_to_utc(DateTime.new(date.year, date.month, date.day, (hour + 1)))
  start_time <= DateTime.now.in_time_zone("UTC") && DateTime.now.in_time_zone("UTC") < end_time
end



