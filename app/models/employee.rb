class Employee < ActiveRecord::Base

  EMAIL_OPTIONS = ["Onboarding", "Offboarding", "Security Access"]

  before_validation :downcase_unique_attrs
  before_validation :strip_whitespace

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :hire_date,
            presence: true

  has_many :emp_transactions # on delete, cascade in db
  has_many :onboarding_infos, through: :emp_transactions
  has_many :offboarding_infos, through: :emp_transactions
  has_many :emp_mach_bundles, through: :emp_transactions
  has_many :machine_bundles, through: :emp_mach_bundles
  has_many :emp_sec_profiles, through: :emp_transactions
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_deltas # on delete, cascade in db
  has_many :emp_access_levels # on delete, cascade in db
  has_many :access_levels, through: :emp_access_levels
  has_many :profiles # on delete, cascade in db

  attr_accessor :nearest_time_zone

  default_scope { order('last_name ASC') }

  [:manager_id, :department, :worker_type, :location, :job_title, :company, :adp_assoc_oid].each do |attribute|
    define_method :"#{attribute}" do
      active_profile.send("#{attribute}")
    end
  end

  def active_profile
    if self.persisted?
      @active_profile ||= self.profiles.active
    else
      @active_profile ||= self.profiles.last
    end
  end

  def employee_id
    active_profile.send(:adp_employee_id)
  end

  def self.find_by_employee_id(value)
    p = Profile.includes(:employee).find_by(adp_employee_id: value)
    if p.present?
      p.employee
    else
      nil
    end
  end

  def downcase_unique_attrs
    self.email = email.downcase if email.present?
  end

  def strip_whitespace
    self.first_name = self.first_name.strip unless self.first_name.nil?
    self.last_name = self.last_name.strip unless self.last_name.nil?
  end

  def self.create_group
    where(:ad_updated_at => nil)
  end

  def self.update_group
    where('ad_updated_at < updated_at')
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

  def self.onboarding_report_group
    where('hire_date >= ?', Date.today)
  end

  def self.offboarding_report_group
    where('employees.termination_date BETWEEN ? AND ?', Date.today - 2.weeks, Date.today)
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

  def fn
    last_name + ", " + first_name
  end

  def cn
    first_name + " " + last_name
  end

  def dn
    "cn=#{cn}," + ou + SECRETS.ad_ou_base
  end

  def ou
    if status == "Terminated"
      "ou=Disabled Users,"
    else
      match = OUS.select { |k,v|
        v[:department].include?(department.name) && v[:country].include?(location.country)
      }

      if match.length == 1
        match.keys[0]
      else
        TechTableMailer.alert_email("WARNING: could not find an exact ou match for #{first_name} #{last_name}; placed in default ou. To remedy, assign appropriate department and country values in Mezzo or contact your developer to create an OU mapping for this department and location combination.").deliver_now
        return "ou=Provisional,ou=Users,"
      end
    end
  end

  def encode_password
    #TODO Replace this with a randomized password that gets sent to the new hire via email/text/???
    "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
  end

  def manager
    Employee.find_by_employee_id(manager_id) if manager_id
  end

  def generated_email
    if email.present?
      email
    elsif sam_account_name.present?
      # TODO: this is always running, what kind of workers shouldn't have email addresses?
      gen_email = sam_account_name + "@opentable.com"
      update_attribute(:email, gen_email)
      gen_email
    else
      nil
    end
  end

  def generated_account_expires
    if termination_date.present?
      date = termination_date
    elsif contract_end_date.present?
      date = contract_end_date
    else
      date = nil
    end

    if date.present?
      # The expiration date needs to be set a day after term date
      # AD expires the account at midnight of the day before the expiry date
      expiration_date = date + 1.day
      time_conversion = ActiveSupport::TimeZone.new(nearest_time_zone).local_to_utc(expiration_date)
      DateTimeHelper::FileTime.wtime(time_conversion)
    else
      NEVER_EXPIRES
    end
  end

  def generated_address
    if home_address_1.present? && home_address_2.present?
      home_address_1 + ", " + home_address_2
    elsif home_address_1.present?
      home_address_1
    else
      nil
    end
  end

  def generated_upn
    sam_account_name + "@opentable.com" if sam_account_name
  end

  def decode_img_code
    image_code ? Base64.decode64(image_code) : nil
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

  def nearest_time_zone
    # US has the broadest time zone spectrum, Pacific time is a sufficient middle ground to capture business hours between NYC and Hawaii
    location.country == 'US' ? "America/Los_Angeles" : TZInfo::Country.get(location.country).zone_identifiers.first
  end

  def onboarding_due_date
    if self.profiles.pending.present?
      puts self.profiles.pending.inspect
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

  def self.email_options(emp_id)
    emp = Employee.find(emp_id)
    emp.termination_date ? EMAIL_OPTIONS : EMAIL_OPTIONS - ["Offboarding"]
  end
end
