class Profile < ActiveRecord::Base
  include AASM

  before_validation :downcase_unique_attrs

  validates :adp_employee_id,
            presence: true
  validates :department_id,
            presence: true
  validates :employee_id,
            presence: true
  validates :job_title_id,
            presence: true
  validates :location_id,
            presence: true
  validates :start_date,
            presence: true
  validates :worker_type_id,
            presence: true

  belongs_to :employee
  belongs_to :department
  belongs_to :job_title
  belongs_to :location
  belongs_to :worker_type

  aasm :column => 'profile_status' do
    state :pending, :initial => true
    state :waiting_for_onboard
    state :onboard_received
    state :active
    state :leave
    state :waiting_for_offboard
    state :offboard_received
    state :terminated

    event :request_manager_action do
      transitions :from => :pending, :to => :waiting_for_onboard, :after => :send_manager_onboarding_form
      transitions :from => :active, :to => :waiting_for_offboard, :after => :send_offboarding_forms
      transitions :from => :terminated, :to => :waiting_for_onboard
    end

    event :rehire_from_event do
      transitions :from => :pending, :to => :waiting_for_onboard
    end

    event :receive_manager_action do
      transitions :from => :waiting_for_onboard, :to => :onboard_received
      transitions :from => :waiting_for_offboard, :to => :offboard_received
    end

    event :start_leave do
      transitions :from => :active, :to => :leave
    end

    event :activate do
      # TODO add guard clause for contracts without contract end date
      # add guard clause if no onboarding form received
      transitions :from => :onboard_received, :to => :active
      transitions :from => :pending, :to => :active
      transitions :from => :leave, :to => :active
    end

    event :terminate do
      transitions :from => :active, :to => :terminated
      transitions :from => :waiting_for_offboard, :to => :terminated
      transitions :from => :offboard_received, :to => :terminated
    end
  end

  scope :regular_worker_type, -> { joins(:worker_type).where(:worker_types => {:kind => "Regular"})}

  def send_manager_onboarding_form
    EmployeeWorker.perform_async("Onboarding", employee_id: self.employee.id)
  end

  def send_offboarding_forms
    TechTableMailer.offboard_notice(self.employee).deliver_now
    EmployeeWorker.perform_async("Offboarding", employee_id: self.employee.id)
  end

  def self.active
    where(:profile_status => "active").last || last
  end

  def self.pending
    where(:profile_status => "pending").last
  end

  def self.terminated
    where(:profile_status => "terminated").last
  end

  def downcase_unique_attrs
    self.adp_employee_id = adp_employee_id.downcase if adp_employee_id.present?
  end
end
