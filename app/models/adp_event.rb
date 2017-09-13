class AdpEvent < ActiveRecord::Base
  STATUS = ["New", "Processed"]
  validates :json,
            presence: true
  validates :msg_id,
            presence: true
  validates :status,
            inclusion: { in: STATUS }

  def self.unprocessed_onboard_evts
    where(kind: ["worker.rehire", "worker.hire"], status: "New")
  end

  def self.onboarding_reminder_group
    reminder_group = []
    unprocessed = AdpEvent.unprocessed_onboard_evts

    unprocessed.each do |e|
      profiler = EmployeeProfile.new
      employee = profiler.build_employee(e)
      reminder_date = employee.onboarding_due_date.to_date - 1.day
      if reminder_date.between?(Date.yesterday, Date.tomorrow)
        reminder_group << e
      end
    end

    reminder_group
  end
end
