class AdpEvent < ActiveRecord::Base
  include AASM

  validates :json,
            presence: true
  validates :msg_id,
            presence: true

  aasm :column => "status" do
    state :new, :initial => true
    state :processed

    event :process do
      transitions from: :new, to: :processed
    end
  end

  def self.unprocessed_onboard_evts
    where(kind: ["worker.rehire", "worker.hire"], status: "new")
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
