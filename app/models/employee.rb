class Employee < ActiveRecord::Base
  include AASM

  default_scope { order('last_name ASC') }

  before_validation :downcase_unique_attrs
  before_validation :strip_whitespace

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
  has_many :direct_reports, class_name: "Employee", foreign_key: "manager_id"
  belongs_to :manager, class_name: "Employee"

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :hire_date,
            presence: true

  scope :active_or_inactive, -> { where('status IN (?)', ["active", "inactive"]) }
  scope :managers, -> { where(management_position: true) }

  aasm :column => "status" do
    error_on_all_events { |e| Rails.logger.info e.message }
    state :created, :initial => true
    state :pending
    state :active
    state :inactive
    state :terminated

    event :hire, binding_event: :wait, after: :onboard_new_position do
      transitions from: :created, to: :pending, after: :create_active_directory_account
    end

    event :rehire, binding_event: :wait, after: :onboard_new_position do
      transitions from: :terminated, to: :pending, after: :update_active_directory_account
    end

    event :rehire_from_event, binding_event: :clear_queue, after: :update_active_directory_account do
      transitions from: :terminated, to: :pending
    end

    event :activate, binding_event: :clear_queue, after: [:activate_profile, :activate_active_directory_account] do
      transitions from: :inactive, to: :active
      transitions from: :pending, to: :active, guard: :activation_allowed?
    end

    event :start_leave do
      transitions from: :active, to: :inactive, after: [:deactivate_active_directory_account, :deactivate_profile]
    end

    event :terminate, binding_event: :clear_queue do
      transitions from: :active, to: :terminated, after: [:deactivate_active_directory_account, :terminate_profile, :offboard]
    end

    event :terminate_immediately do
      transitions from: :active, to: :terminated, after: [:deactivate_active_directory_account, :offboard, :send_techtable_offboard_instructions]
    end

    event :leave_immediately do
      transitions from: :active, to: :inactive, after: :deactivate_active_directory_account
    end
  end

  aasm(:request_status) do
    state :none, :initial => true
    state :waiting
    state :completed

    event :wait do
      transitions from: :none, to: :waiting
    end

    event :complete do
      transitions from: [:none, :waiting, :completed], to: :completed
    end

    event :clear_queue do
      transitions from: [:completed, :waiting, :none], to: :none
    end

    event :start_offboard_process do
      transitions from: :none, to: :waiting, after: [:update_active_directory_account, :prepare_termination]
    end
  end

  [:department, :worker_type, :location, :job_title, :company, :adp_assoc_oid].each do |attribute|
    define_method :"#{attribute}" do
      current_profile.try(:send, "#{attribute}")
    end
  end

  def prepare_termination
    EmployeeService::Offboard.new(self).prepare_termination
  end

  def onboard_new_position
    EmployeeService::Onboard.new(self).process!
  end

  def activation_allowed?
    ActivationPolicy.new(self).allowed?
  end

  def activate_profile
    self.current_profile.activate!
  end

  def employee_id
    current_profile.try(:send, :adp_employee_id)
  end

  def deactivate_profile
    self.current_profile.start_leave!
  end

  def terminate_profile
    self.current_profile.terminate!
  end

  def self.find_by_employee_id(value)
    p = Profile.find_by(adp_employee_id: value)
    return nil if p.blank?
    p.employee
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

  def ad_attrs
    {
      cn: cn,
      dn: dn,
      objectclass: ["top", "person", "organizationalPerson", "user"],
      givenName: first_name,
      sn: last_name,
      displayName: cn,
      userPrincipalName: generated_upn,
      sAMAccountName: sam_account_name,
      manager: manager.try(:dn),
      mail: generated_email,
      unicodePwd: encode_password,
      co: location.country,
      accountExpires: generated_account_expires,
      title: job_title.name,
      description: job_title.name,
      employeeType: worker_type.try(:name),
      physicalDeliveryOfficeName: location.name,
      department: department.name,
      employeeID: employee_id,
      telephoneNumber: office_phone,
      streetAddress: generated_address,
      l: home_city,
      st: home_state,
      postalCode: home_zip,
      # thumbnailPhoto: decode_img_code
      # TODO bring back thumbnail photo when we pull the info from ADP or other source
      # Make cure to comment back in the relevant tests in models/employee_spec.rb, and tasks/employee_spec.rb
    }
  end

  def generated_upn
    sam_account_name + "@opentable.com" if sam_account_name
  end

  def decode_img_code
    image_code ? Base64.decode64(image_code) : nil
  end

  def generated_address
    return nil if home_address_1.blank?
    return home_address_1 + ", " + home_address_2 if home_address_1.present? && home_address_2.present?
    home_address_1
  end

  def generated_account_expires
    # The expiration date needs to be set a day after term date
    # AD expires the account at midnight of the day before the expiry date
    end_date = contract_end_date if contract_end_date.present?
    end_date = termination_date if termination_date.present?

    if end_date
      expiration_date = end_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new(nearest_time_zone).local_to_utc(expiration_date)
      DateTimeHelper::FileTime.wtime(time_conversion)
    else
      NEVER_EXPIRES
    end
  end

  def generated_email
    return nil if email.blank? && sam_account_name.blank?
    return email if email.present?
    # TODO: this is always running, what kind of workers shouldn't have email addresses?
    gen_email = sam_account_name + "@opentable.com"
    update_attribute(:email, gen_email)
    gen_email
  end

  def dn
    "cn=#{cn}," + ou + SECRETS.ad_ou_base
  end

  def encode_password
    #TODO Replace this with a randomized password that gets sent to the new hire via email/text/???
    "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
  end

  def ou
    return "ou=Disabled Users," if status == "terminated"

    match = OUS.select { |k,v|
      v[:department].include?(department.name) && v[:country].include?(location.country)
    }
    return match.keys[0] if match.length == 1

    # put worker in provisional OU if it cannot find another one
    TechTableMailer.alert_email("WARNING: could not find an exact ou match for #{first_name} #{last_name}; placed in default ou. To remedy, assign appropriate department and country values in Mezzo or contact your developer to create an OU mapping for this department and location combination.").deliver_now
    "ou=Provisional,ou=Users,"
  end

  def self.search(term)
    where("lower(last_name) LIKE ? OR lower(first_name) LIKE ? ", "%#{term.downcase}%", "%#{term.downcase}%").reorder("last_name ASC")
  end

  def self.search_email(term)
    where("lower(email) LIKE ?", "%#{term.downcase}%")
  end

  def self.leave_return_group
    where('leave_return_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow)
  end

  def self.deactivation_group
    where('contract_end_date BETWEEN ? AND ? OR leave_start_date BETWEEN ? AND ? OR termination_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow, Date.yesterday, Date.tomorrow)
  end

  def self.full_termination_group
    where('termination_date BETWEEN ? AND ?', 8.days.ago, 7.days.ago)
  end

  def self.offboarding_report_group
    where('employees.termination_date BETWEEN ? AND ?', Date.today - 2.weeks, Date.today)
  end

  def self.onboarding_reminder_group
    missing_onboards = Employee.where(status: "pending", request_status: "waiting")
    missing_onboards.select { |e| e if (e.onboarding_due_date.to_date - 1.day).between?(Date.yesterday, Date.tomorrow) }
  end

  def current_profile
    # if employee data is not persisted, like when previewing employee data from an event
    # scope on profiles is not available, so must access by method last
    @current_profile ||= self.profiles.last if !self.persisted?

    case self.status
    when "active"
      @current_profile ||= self.profiles.active.last
    when "inactive"
      @current_profile ||= self.profiles.leave.last
    when "pending"
      @current_profile ||= self.profiles.pending.last
    when "terminated"
      @current_profile ||= self.profiles.terminated.last
    else
      self.profiles.last
    end
  end

  def start_date
    current_profile.start_date.strftime("%b %e, %Y")
  end

  def is_rehire?
    status == "pending" && profiles.terminated.present?
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

  def downcase_unique_attrs
    self.email = email.downcase if email.present?
    self.status = status.downcase if status.present?
  end

  def strip_whitespace
    self.first_name = self.first_name.strip unless self.first_name.nil?
    self.last_name = self.last_name.strip unless self.last_name.nil?
  end

  def offboarding_cutoff
    if self.termination_date.present?
      # noon on termination date, when we send offboarding instructions to techtable
      ActiveSupport::TimeZone.new(self.nearest_time_zone).local_to_utc(DateTime.new(self.termination_date.year, self.termination_date.month, self.termination_date.day, 12))
    end
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
      start_date = self.profiles.pending.reorder(:created_at).last.start_date
    else
      # usually only used when building employee from event and not persisted
      start_date = self.profiles.last.start_date
    end
    # plus 9.hours to account for the beginning of the business day
    if location.country == "US" || location.country == "GB"
      5.business_days.before(start_date + 9.hours).strftime("%b %e, %Y")
    else
      10.business_days.before(start_date + 9.hours).strftime("%b %e, %Y")
    end
  end

  def email_options
    self.termination_date ? EMAIL_OPTIONS : EMAIL_OPTIONS - ["Offboarding"]
  end
end
