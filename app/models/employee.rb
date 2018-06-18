class Employee < ActiveRecord::Base
  include AASM

  has_ancestry

  before_validation :downcase_unique_attrs
  before_validation :strip_whitespace

  EMAIL_OPTIONS = ["Onboarding", "Offboarding", "Security Access"]

  attr_accessor :nearest_time_zone

  has_many :approver_designations, inverse_of: :employee, dependent: :destroy
  has_one :current_profile, -> { where(profiles: { primary: true }) }, class_name: 'Profile', autosave: true
  has_many :profiles, autosave: true
  has_many :emp_transactions # on delete, cascade in db
  has_many :onboarding_infos, through: :emp_transactions
  has_many :offboarding_infos, through: :emp_transactions
  has_many :emp_mach_bundles, through: :emp_transactions
  has_many :machine_bundles, through: :emp_mach_bundles
  has_many :emp_sec_profiles, through: :emp_transactions
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_deltas # on delete, cascade in db
  has_many :direct_reports, class_name: "Employee", foreign_key: "manager_id"
  has_many :addresses, as: :addressable
  belongs_to :manager, class_name: "Employee"
  accepts_nested_attributes_for :current_profile

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :hire_date,
            presence: true

  scope :active_or_inactive, -> { where('status IN (?)', ["active", "inactive"]) }
  scope :inactives, -> { where(status: 'inactive') }
  scope :managers, -> { where(management_position: true) }
  scope :offboards, -> { where('termination_date BETWEEN ? AND ? OR offboarded_at BETWEEN ? AND ? OR contract_end_date BETWEEN ? AND ?', 2.weeks.ago, Date.today, 2.weeks.ago, Date.today, 2.weeks.ago, Date.today) }
  scope :sorted_by, lambda { |sort_key|
    direction = (sort_key =~ /desc$/) ? 'DESC' : 'ASC'
    case sort_key.to_s
    when /^name/
      order("LOWER(last_name) #{direction}")
    when /^termination_date/
      order("termination_date #{direction}")
    when /^contract_end_date/
      order("contract_end_date #{direction}")
    when /^offboarded_at/
      order("offboarded_at #{direction}")
    when /^leave_start_date/
      order("leave_start_date #{direction}")
    end
  }
  scope :with_location_id, lambda { |location_ids|
    joins(:profiles, profiles: :location)
    .where('profiles.location_id IN (?)', [*location_ids])
  }
  scope :with_department_id, lambda { |department_ids|
    joins(:profiles, profiles: :department)
    .where('profiles.department_id IN (?)', [*department_ids])
  }
  scope :with_worker_type_id, lambda { |worker_type_ids|
    joins(:profiles, profiles: :worker_type)
    .where('profiles.worker_type_id IN (?)', [*worker_type_ids])
  }
  scope :with_status, lambda { |statuses|
    where(status: [*statuses])
  }
  scope :search_query, lambda { |query|
    return nil if query.blank?
    terms = query.downcase.split(/\s+/)
    terms = terms.map { |e| (e.gsub('*', '%') + '%').gsub(/%+/, '%') }
    num_or_conds = 2
    where(
      terms.map { |term|
        "(LOWER(employees.first_name) LIKE ? OR LOWER(employees.last_name) LIKE ?)"
      }.join(' AND '),
    *terms.map { |e| [e] * num_or_conds }.flatten
  )
  }

  aasm :column => "status" do
    error_on_all_events { |e| Rails.logger.info e.message }
    state :created, initial: true
    state :pending
    state :active, before_enter: :activate_profile
    state :inactive, before_enter: :leave_profile
    state :terminated, before_enter: :terminate_profile

    event :hire do
      transitions from: [:created, :terminated], to: :pending
      transitions from: :active, to: :active
    end

    event :rehire_from_event, binding_event: :clear_queue do
      transitions from: :terminated, to: :pending, after: :update_active_directory_account
    end

    event :activate, guard: :activation_allowed?, binding_event: :clear_queue do
      # ADP sometimes updates the status before we want to activate worker
      transitions from: [:pending, :inactive, :active], to: :active, after: :activate_active_directory_account
    end

    event :start_leave do
      transitions from: [:active, :inactive], to: :inactive, after: :deactivate_active_directory_account
    end

    event :terminate, binding_event: :clear_queue do
      transitions from: :active, to: :terminated, after: :execute_termination
    end

    event :terminate_immediately, binding_event: :clear_queue do
      transitions from: :active, to: :terminated, after: [:update_active_directory_account, :send_techtable_offboard_instructions, :execute_termination]
    end
  end

  aasm(:request_status) do
    state :none, :initial => true
    state :waiting
    state :completed

    event :wait do
      transitions from: [:none, :completed, :waiting], to: :waiting
    end

    event :complete do
      transitions from: [:none, :completed, :waiting], to: :completed
    end

    event :clear_queue do
      transitions from: [:none, :completed, :waiting], to: :none
    end

    event :start_offboard_process do
      transitions from: [:none, :completed, :waiting], to: :waiting, after: [:update_active_directory_account, :prepare_termination]
    end
  end

  filterrific(
    default_filter_params: { sorted_by: 'name_asc' },
    available_filters: [
      :search_query,
      :with_status,
      :with_location_id,
      :with_department_id,
      :with_worker_type_id,
      :sorted_by
    ]
  )

  def self.status_options
    ['active', 'inactive', 'terminated', 'pending']
  end

  def self.options_for_sort
    [
      ['Name (a-z)', 'name_asc'],
      ['Hire date (newest first)', 'hire_date_desc'],
      ['Hire date (oldest first)', 'hire_date_asc'],
      ['Contract end date (newest first)', 'contract_end_date_dec'],
      ['Contract end date (oldest first)', 'contract_end_date_asc'],
      ['Termination date (newest first)', 'termination_date_desc'],
      ['Termination date (oldest first)', 'termination_date_asc']
    ]
  end

  def self.options_for_offboard_sort
    [
      ['Name (a-z)', 'name_asc'],
      ['Termination date (newest first)', 'termination_date_desc'],
      ['Termination date (oldest first)', 'termination_date_asc'],
      ['Contract end date (newest first)', 'contract_end_date_desc'],
      ['Contract end date (oldest first)', 'contract_end_date_asc'],
      ['Offboarded date (newest first)', 'offboarded_at_desc'],
      ['Offboarded date (oldest first)', 'offboarded_at_asc'],
    ]
  end

  def self.options_for_inactive_sort
    [
      ['Name (a-z)', 'name_asc'],
      ['Leave start date (newest first)', 'leave_start_date']
    ]
  end

  [:department, :worker_type, :location, :job_title, :business_unit, :adp_assoc_oid].each do |attribute|
    define_method :"#{attribute}" do
      current_profile.try(:send, "#{attribute}")
    end
  end

  def self_and_descendants
    self.descendants << self
  end

  def current_profile
    @current_profile || profiles.detect{ |p| p.primary? }
  end

  def build_current_profile(attributes = {})
    handle_existing_current_profile
    @current_profile = self.profiles.build(attributes.merge({ primary: true }))
  end

  def current_profile=(profile_or_id)
    if profile_or_id
      new_current_profile = profile_or_id.is_a?(Profile) ? profile_or_id : self.profiles.find(profile_or_id)
      new_current_profile.try(:assign_attributes, primary: true, employee: self)
    end

    handle_existing_current_profile

    self.profiles.target << new_current_profile if new_current_profile && new_current_profile.new_record?
    @current_profile = new_current_profile
  end

  def handle_existing_current_profile
    if self.current_profile
      if self.current_profile.new_record?
        self.profiles.detect{ |p| p.primary? }.mark_for_destruction
      end
      self.profiles.detect{ |p| p.primary? }.try(:assign_attributes, { primary: false })
    end
  end

  def onboard_new_position
    EmployeeService::Onboard.new(self).process!
  end

  def activation_allowed?
    ActivationPolicy.new(self).allowed?
  end

  def prepare_termination
    EmployeeService::Offboard.new(self).prepare_termination
  end

  def execute_termination
    EmployeeService::Offboard.new(self).execute_termination
  end

  def activate_profile
    current_profile.activate!
  end

  def employee_id
    current_profile.try(:send, :adp_employee_id)
  end

  def leave_profile
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
      streetAddress: address.try(:complete_street),
      l: address.try(:city),
      st: address.try(:state_territory),
      postalCode: address.try(:postal_code)
    }
  end

  def generated_upn
    sam_account_name + "@opentable.com" if sam_account_name
  end

  def decode_img_code
    image_code ? Base64.decode64(image_code) : nil
  end

  def address
    addresses.last if addresses.present?
  end

  def generated_account_expires
    # The expiration date needs to be set a day after term date
    # AD expires the account at midnight of the day before the expiry date

    if offboard_date.present?
      expiration_date = offboard_date + 1.day
      time_conversion = ActiveSupport::TimeZone.new(nearest_time_zone).local_to_utc(expiration_date)
      DateTimeHelper::FileTime.wtime(time_conversion)
    else
      NEVER_EXPIRES
    end
  end

  def generated_email
    return nil if email.blank? && sam_account_name.blank?
    return email if email.present?
    gen_email = sam_account_name + "@opentable.com"
    update_attribute(:email, gen_email)
    gen_email
  end

  def dn
    "cn=#{cn}," + ou + SECRETS.ad_ou_base
  end

  def encode_password
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

  def self.onboarding_reminder_group
    missing_onboards = Employee.where(status: "pending", request_status: "waiting")
    missing_onboards.select { |e| e if (e.onboarding_due_date.to_date - 1.day).between?(Date.yesterday, Date.tomorrow) }
  end

  def start_date
    current_profile.start_date
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
    return nil if termination_date.blank? && contract_end_date.blank?
    end_date = termination_date.present? ? termination_date : contract_end_date

    # noon on termination date, when we send offboarding instructions to techtable
    ActiveSupport::TimeZone.new(nearest_time_zone).local_to_utc(DateTime.new(end_date.year, end_date.month, end_date.day, 12))
  end

  def fn
    last_name + ", " + first_name
  end

  def cn
    first_name + " " + last_name
  end

  def full_name
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
      5.business_days.before(start_date + 9.hours)
    else
      10.business_days.before(start_date + 9.hours)
    end
  end

  def email_options
    offboard_date.present? ? EMAIL_OPTIONS : EMAIL_OPTIONS - ["Offboarding"]
  end

  def needs_contract_end_confirmation?
    contract_end_date.present? && termination_date.blank?
  end

  def offboard_date
    return contract_end_date if needs_contract_end_confirmation?
    termination_date
  end

  # Date of last meaningful change to employee record.
  # Considers the following categories:
  # Onboarding form submitted, offboarding form submitted, last employee delta created, profile created, employee created
  def last_changed_at
    changes = []
    deltas = self.emp_deltas.where("before != '' AND after != ''")

    changes << deltas.last.created_at if deltas.present?
    changes << self.onboarding_infos.last.created_at.to_datetime if self.onboarding_infos.present?
    changes << self.offboarding_infos.last.created_at.to_datetime if self.offboarding_infos.present?
    changes << self.current_profile.created_at.to_datetime if self.current_profile.present?

    return changes.sort.last if changes.present?
    created_at.to_datetime
  end

  def buddy
    return nil if self.onboarding_infos.blank?
    return nil if self.onboarding_infos.last.buddy_id.blank?

    buddy_id = self.onboarding_infos.last.buddy_id
    buddy = Employee.find(buddy_id)

    return buddy if buddy.present?
  end
end
