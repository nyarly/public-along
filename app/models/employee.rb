class Employee < ActiveRecord::Base
  include EmpLdapEntry
  include AASM

  default_scope { order('last_name ASC') }

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

  before_validation :downcase_unique_attrs
  before_validation :downcase_status
  before_validation :strip_whitespace

  scope :active_or_inactive, -> { where('status IN (?)', ["active", "inactive"]) }

  aasm :column => 'status' do
    state :created, :initial => true
    state :pending
    state :active
    state :inactive
    state :terminated

    event :hire do
      after do
        Employee.check_manager(self.manager_id)
      end
      transitions :from => :created, :to => :pending, :after => [:create_active_directory_account, :send_manager_onboarding_form]
    end

    event :rehire do
      transitions :from => :terminated, :to => :pending
    end

    event :activate do
      transitions :from => :pending, :to => :active, :after => [:activate_active_directory_account, :update_profile]
    end

    event :start_leave do
      transitions :from => :active, :to => :inactive, :after => [:deactivate_active_directory_account]
    end

    event :terminate do
      transitions :from => :active, :to => :terminated, :after => [:deactivate_active_directory_account, :offboard]
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

  [:manager_id, :department, :worker_type, :location, :job_title, :company, :adp_assoc_oid].each do |attribute|
    define_method :"#{attribute}" do
      current_profile.try(:send, "#{attribute}")
    end
  end

  def update_profile
    current_profile.activate_profile!
  end

  def current_profile
    # if employee data is not persisted, like when previewing employee data from an event
    # scope on profiles is not available, so must access by method last
    if self.persisted?
      if self.status == "active"
        @current_profile ||= self.profiles.active
      elsif self.status == "inactive"
        @current_profile ||= self.profiles.inactive
      elsif self.status == "pending"
        @current_profile ||= self.profiles.last
      elsif self.status == "terminated"
        @current_profile ||= self.profiles.terminated
      else
        self.profiles.last
      end
    else
      @current_profile ||= self.profiles.last
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

  def send_manager_onboarding_form
    EmployeeWorker.perform_async("Onboarding", employee_id: self.id)
  end

  def send_techtable_offboard_instructions
    TechTableMailer.offboard_instructions(self).deliver_now
  end

  def offboard
    service = OffboardingService.new
    service.offboard([self])
  end

  def self.activation_group
    where('hire_date BETWEEN ? AND ? OR leave_return_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow)
  end

  def self.deactivation_group
    where('contract_end_date BETWEEN ? AND ? OR leave_start_date BETWEEN ? AND ? OR termination_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow)
  end

  def self.full_termination_group
    where('termination_date BETWEEN ? AND ?', 8.days.ago, 7.days.ago)
  end

  def self.onboarding_report_group
    where('hire_date >= ?', Date.today)
  end

  def self.offboarding_report_group
    where('employees.termination_date BETWEEN ? AND ?', Date.today - 2.weeks, Date.today)
  end

  def downcase_unique_attrs
    self.email = email.downcase if email.present?
  end

  def downcase_status
    self.status = status.downcase if status.present?
  end

  def strip_whitespace
    self.first_name = self.first_name.strip unless self.first_name.nil?
    self.last_name = self.last_name.strip unless self.last_name.nil?
  end

  def is_contingent_worker?
    worker_type.kind == "Temporary" || worker_type.kind == "Contractor"
  end

  def self.managers
    joins(:emp_sec_profiles)
    .where('emp_sec_profiles.security_profile_id = ?', SecurityProfile.find_by(name: 'Basic Manager').id)
  end

  def contract_end_date_needed?
    worker_type.kind != "Regular" && contract_end_date.blank?
  end

  def self.direct_reports_of(manager_emp_id)
    joins(:profiles).where("profiles.manager_id LIKE ?", manager_emp_id)
  end

  def onboarding_complete?
    self.onboarding_infos.count > 0
  end

  def offboarding_complete?
    self.offboarding_infos.count > 0
  end

  def active_security_profiles
    self.security_profiles.references(:emp_transactions).references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
  end

  def security_profiles_to_revoke
    current_sps = self.security_profiles.references(:emp_transactions).references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
    current_department_sps = SecurityProfile.find_profiles_for(self.department.id)
    current_sps - current_department_sps
  end

  def revoked_security_profiles
    self.security_profiles.references(:emp_sec_profiles).where("emp_sec_profiles.revoking_transaction_id IS NOT NULL")
  end

  def self.search(term)
    where("lower(last_name) LIKE ? OR lower(first_name) LIKE ? ", "%#{term.downcase}%", "%#{term.downcase}%").reorder("last_name ASC")
  end

  def self.search_email(term)
    where("lower(email) LIKE ?", "%#{term.downcase}%")
  end

  def fn
    last_name + ", " + first_name
  end

  def cn
    first_name + " " + last_name
  end

  def manager
    Employee.find_by_employee_id(manager_id) if manager_id
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

  def self.onboarding_reminder_group
    reminder_group = []
    missing_onboards = Employee.where(status: "pending").joins('LEFT OUTER JOIN emp_transactions ON employees.id = emp_transactions.employee_id').group('employees.id').having('count(emp_transactions) = 0')

    missing_onboards.each do |e|
      reminder_date = e.onboarding_due_date.to_date - 1.day
      if reminder_date.between?(Date.yesterday, Date.tomorrow)
        reminder_group << e
      end
    end
    reminder_group
  end

  def offboarding_cutoff
    if self.termination_date.present?
      # noon on termination date, when we send offboarding instructions to techtable
      ActiveSupport::TimeZone.new(self.nearest_time_zone).local_to_utc(DateTime.new(self.termination_date.year, self.termination_date.month, self.termination_date.day, 12))
    end
  end

  def self.check_manager(emp_id)
    emp = Employee.find_by_employee_id(emp_id)

    if emp.present? && !Employee.managers.include?(emp)
      sp = SecurityProfile.find_by(name: "Basic Manager")

      emp_trans = EmpTransaction.new(
        kind: "Service",
        notes: "Manager permissions added by Mezzo",
        employee_id: emp.id
      )

      emp_trans.emp_sec_profiles.build(
        security_profile_id: sp.id
      )

      emp_trans.save!

      if emp_trans.emp_sec_profiles.count > 0
        sas = SecAccessService.new(emp_trans)
        sas.apply_ad_permissions
      end
    end
  end

  def email_options
    self.termination_date ? EMAIL_OPTIONS : EMAIL_OPTIONS - ["Offboarding"]
  end
end
