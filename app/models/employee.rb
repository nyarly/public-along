class Employee < ActiveRecord::Base
  TYPES = ["Agency Contractor", "Independent Contractor", "Service Provider", "Intern", "Regular", "Temporary"]
  EMAIL_OPTIONS = ["Onboarding", "Offboarding", "Security Access"]

  before_validation :downcase_unique_attrs
  before_validation :strip_whitespace

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :hire_date,
            presence: true
  validates :department_id,
            presence: true
  validates :location_id,
            presence: true
  validates :email,
            allow_nil: true,
            uniqueness: true
  validates :employee_id,
            uniqueness: { message: "Worker ID has already been taken" }

  belongs_to :department
  belongs_to :location
  belongs_to :worker_type
  belongs_to :job_title
  has_many :emp_sec_profiles
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_transactions, through: :emp_sec_profiles
  has_many :onboarding_infos
  has_many :offboarding_infos
  has_many :emp_deltas

  attr_accessor :nearest_time_zone

  default_scope { order('first_name ASC') }

  def downcase_unique_attrs
    self.email = email.downcase if email.present?
    self.employee_id = employee_id.downcase if employee_id.present?
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
    where('manager_id = ?', manager_emp_id)
  end

  def self.onboarding_report_group
    where('hire_date >= ?', Date.today)
  end

  def self.offboarding_report_group
    where('employees.termination_date BETWEEN ? AND ?', Date.today - 2.weeks, Date.today).uniq
  end

  def self.offboard_group
    joins(:offboarding_infos)
    .where('employees.termination_date BETWEEN ? AND ?', Date.today - 1.week, Date.today).uniq
  end

  def onboarding_complete?
    self.onboarding_infos.count > 0
  end

  def offboarding_complete?
    self.offboarding_infos.count > 0
  end

  def active_security_profiles
    self.security_profiles.references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
  end

  def security_profiles_to_revoke
    current_sps = self.security_profiles.references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
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
    Employee.find_by(employee_id: manager_id) if manager_id
  end

  def generated_email
    if email.present?
      email
    elsif sam_account_name.present? && worker_type.name != "Vendor"
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
      workdayUsername: workday_username,
      co: location.country,
      accountExpires: generated_account_expires,
      title: job_title.try(:name),
      description: job_title.try(:name),
      employeeType: worker_type.try(:name),
      physicalDeliveryOfficeName: location.name,
      department: department.name,
      employeeID: employee_id,
      telephoneNumber: office_phone,
      streetAddress: generated_address,
      l: home_city,
      st: home_state,
      postalCode: home_zip,
      thumbnailPhoto: decode_img_code
    }
  end

  def nearest_time_zone
    # US has the broadest time zone spectrum, Pacific time is a sufficient middle ground to capture business hours between NYC and Hawaii
    location.country == 'US' ? "America/Los_Angeles" : TZInfo::Country.get(location.country).zone_identifiers.first
  end

  def onboarding_due_date
    # plus 9.hours to account for the beginning of the business day
    if location.country == "US" || location.country == "GB"
      5.business_days.before(hire_date + 9.hours).strftime("%b %e, %Y")
    else
      10.business_days.before(hire_date + 9.hours).strftime("%b %e, %Y")
    end
  end

  def self.check_manager(emp_id)
    emp = Employee.find_by(employee_id: emp_id)
    if emp.present? && !Employee.managers.include?(emp)
      sp = SecurityProfile.find_by(name: "Basic Manager")
      emp.security_profiles << sp

      ads = ActiveDirectoryService.new
      sp.access_levels.each do |al|
        sg = al.ad_security_group
        ads.add_to_sec_group(sg, emp) unless sg.blank?
      end
    end
  end

  def self.email_options(emp_id)
    emp = Employee.find(emp_id)
    emp.termination_date ? EMAIL_OPTIONS : EMAIL_OPTIONS - ["Offboarding"]
  end
end
