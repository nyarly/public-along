class Employee < ActiveRecord::Base
  extend Groups
  extend Search
  include AASM
  include CurrentProfile
  include LdapEntry
  include Manager
  include SecurityProfiles

  default_scope { order('last_name ASC') }

  before_validation :downcase_unique_attrs
  before_validation :strip_whitespace
  # after_update :update_active_directory_account

  EMAIL_OPTIONS = ["Onboarding", "Offboarding", "Security Access"]

  attr_accessor :nearest_time_zone

  has_many :emp_transactions # on delete, cascade in db
  has_many :onboarding_infos, through: :emp_transactions
  has_many :offboarding_infos, through: :emp_transactions
  has_many :emp_mach_bundles, through: :emp_transactions
  has_many :machine_bundles, through: :emp_mach_bundles
  has_many :emp_sec_profiles, through: :emp_transactions
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_deltas # on delete, cascade in db
  has_many :profiles # on delete, cascade in db

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :hire_date,
            presence: true

  scope :active_or_inactive, -> { where('status IN (?)', ["active", "inactive"]) }

  aasm(:status) do
    state :created, :initial => true
    state :pending
    state :active
    state :inactive
    state :terminated

    event :hire, :binding_event => :wait do
      after do
        check_manager
        add_basic_security_profile
        send_manager_onboarding_form
      end
      transitions :from => :created, :to => :pending, :after => :create_active_directory_account
    end

    event :rehire do
      transitions :from => :terminated, :to => :pending, :after => :update_active_directory_account
    end

    event :rehire_from_event do
      transitions :from => :terminated, :to => :pending
    end

    event :activate do
       # TODO add guard clause for contracts without contract end date
      # add guard clause if no onboarding form received
      after do
        self.current_profile.activate!
      end
      transitions :from => [:pending, :inactive], :to => :active, :after => :activate_active_directory_account
    end

    event :start_leave do
      after do
        self.current_profile.start_leave!
      end
      transitions :from => :active, :to => :inactive, :after => :deactivate_active_directory_account
    end

    event :terminate, :binding_event => :clear do
      after do
        self.current_profile.terminate!
      end
      transitions :from => :active, :to => :terminated
    end

    # edge case
    # event :will_not_start do
    #   transitions :from => :pending, :to => :terminated
    # end

    # edge case
    # event :terminate_from_leave do
    #   transitions :from => :inactive, :to => :terminated
    # end
  end

  aasm(:request_status) do
    state :none, :initial => true
    state :waiting
    state :completed

    event :wait do
      transitions :from => :none, :to => :waiting
    end

    event :complete do
      transitions :from => :waiting, :to => :complete
    end

    event :clear do
      transitions :from => [:complete, :waiting], :to => :none
    end
  end

  [:manager_id, :department, :worker_type, :location, :job_title, :company, :adp_assoc_oid].each do |attribute|
    define_method :"#{attribute}" do
      current_profile.try(:send, "#{attribute}")
    end
  end

  def employee_id
    current_profile.try(:send, :adp_employee_id)
  end

  def self.find_by_employee_id(value)
    p = Profile.find_by(adp_employee_id: value)
    if p.present?
      p.employee
    else
      nil
    end
  end

  def update_active_directory_account
    ads = ActiveDirectoryService.new
    ads.update([self])
  end

  def create_active_directory_account
    ads = ActiveDirectoryService.new
    ads.create_disabled_accounts([self])
  end

  def activate_active_directory_account
    ads = ActiveDirectoryService.new
    ads.activate([self])
  end

  def deactivate_active_directory_account
    ads = ActiveDirectoryService.new
    ads.deactivate([self])
  end

  def send_techtable_offboard_instructions
    TechTableMailer.offboard_instructions(self).deliver_now
  end

  def offboard
    service = OffboardingService.new
    service.offboard([self])
  end

  def send_manager_onboarding_form
    EmployeeWorker.perform_async("Onboarding", employee_id: self.employee.id)
  end

  def send_offboarding_forms
    TechTableMailer.offboard_notice(self.employee).deliver_now
    EmployeeWorker.perform_async("Offboarding", employee_id: self.employee.id)
  end

  def downcase_unique_attrs
    self.email = email.downcase if email.present?
    self.status = status.downcase if status.present?
  end

  def strip_whitespace
    self.first_name = self.first_name.strip unless self.first_name.nil?
    self.last_name = self.last_name.strip unless self.last_name.nil?
  end

  def is_contingent_worker?
    worker_type.kind == "Temporary" || worker_type.kind == "Contractor"
  end

  def contract_end_date_needed?
    worker_type.kind != "Regular" && contract_end_date.blank?
  end

  def onboarding_complete?
    self.onboarding_infos.count > 0
  end

  def offboarding_complete?
    self.offboarding_infos.count > 0
  end

  def fn
    last_name + ", " + first_name
  end

  def cn
    first_name + " " + last_name
  end

  def nearest_time_zone
    # US has the broadest time zone spectrum, Pacific time is a sufficient middle ground to capture business hours between NYC and Hawaii
    location.country == 'US' ? "America/Los_Angeles" : TZInfo::Country.get(location.country).zone_identifiers.first
  end

  def onboarding_due_date
    # if employee data is not persisted, like when previewing employee data from an event
    # scope on profiles is not available, so must access by method last
    if self.profiles.pending.present?
      start_date = self.profiles.pending.start_date
    else
      start_date = self.profiles.last.start_date
    end
    # plus 9.hours to account for the beginning of the business day
    if location.country == "US" || location.country == "GB"
      5.business_days.before(start_date + 9.hours).strftime("%b %e, %Y")
    else
      10.business_days.before(start_date + 9.hours).strftime("%b %e, %Y")
    end
  end

  def offboarding_cutoff
    if self.termination_date.present?
      # noon on termination date, when we send offboarding instructions to techtable
      ActiveSupport::TimeZone.new(self.nearest_time_zone).local_to_utc(DateTime.new(self.termination_date.year, self.termination_date.month, self.termination_date.day, 12))
    end
  end

  def email_options
    self.termination_date ? EMAIL_OPTIONS : EMAIL_OPTIONS - ["Offboarding"]
  end
end
