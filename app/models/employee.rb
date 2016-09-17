class Employee < ActiveRecord::Base
  TYPES = ["Regular", "Temporary", "Contingent", "Agency", "Contract"]

  validates :first_name,
            presence: true
  validates :last_name,
            presence: true
  validates :department_id,
            presence: true
  validates :location_id,
            presence: true
  validates :email,
            case_sensitive: false,
            allow_nil: true,
            uniqueness: true
  validates :employee_id,
            uniqueness: true,
            case_sensitive: false

  belongs_to :department
  belongs_to :location
  has_many :emp_sec_profiles
  has_many :security_profiles, through: :emp_sec_profiles
  has_many :emp_transactions, through: :emp_sec_profiles
  has_many :offboarding_infos

  attr_accessor :sAMAccountName
  attr_accessor :nearest_time_zone

  default_scope { order('last_name ASC') }

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

  def self.termination_group
    where('termination_date BETWEEN ? AND ?', 30.days.ago, 31.days.ago)
  end

  def contract_end_date_needed?
    employee_type != "Regular" && contract_end_date.blank?
  end

  def self.direct_reports_of(manager_emp_id)
    where('manager_id = ?', manager_emp_id)
  end

  def onboarding_complete?
    self.emp_transactions.where(kind: "Onboarding").count > 0
  end

  def active_security_profiles
    self.security_profiles.references(:emp_sec_profiles).where(emp_sec_profiles: {revoking_transaction_id: nil})
  end

  def revoked_security_profiles
    self.security_profiles.references(:emp_sec_profiles).where("emp_sec_profiles.revoking_transaction_id IS NOT NULL")
  end

  def cn
    first_name + " " + last_name
  end

  def dn
    "cn=#{cn}," + ou + SECRETS.ad_ou_base
  end

  def ou
    match = OUS.select { |k,v|
      v[:department].include?(department.name) && v[:country].include?(location.country)
    }

    if match.length == 1
      match.keys[0]
    else
      TechTableMailer.alert_email("WARNING: could not find an exact ou match for #{first_name} #{last_name}; placed in default ou. To remedy, assign appropriate department and country values in Workday.").deliver_now
      return ""
    end
  end

  def encode_password
    #TODO Replace this with a randomized password that gets sent to the new hire via email/text/???
    "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
  end

  def generated_email
    if email.present?
      email
    elsif sAMAccountName.present? && employee_type != "Vendor"
      gen_email = sAMAccountName + "@opentable.com"
      update_attribute(:email, gen_email)
      gen_email
    else
      nil
    end
  end

  def generated_account_expires
    if termination_date.present?
      DateTimeHelper::FileTime.wtime(termination_date)
    elsif contract_end_date.present?
      DateTimeHelper::FileTime.wtime(contract_end_date)
    else
      # In AD, this value indicates that the account never expires
      "9223372036854775807"
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

  def decode_img_code
    image_code ? Base64.decode64(image_code) : nil
  end

  def ad_attrs
    {
      cn: cn,
      objectclass: ["top", "person", "organizationalPerson", "user"],
      givenName: first_name,
      sn: last_name,
      sAMAccountName: sAMAccountName,
      mail: generated_email,
      unicodePwd: encode_password,
      workdayUsername: workday_username,
      co: location.country,
      accountExpires: generated_account_expires,
      title: business_title,
      description: business_title,
      employeeType: employee_type,
      physicalDeliveryOfficeName: location.name,
      department: department.name,
      employeeID: employee_id,
      mobile: personal_mobile_phone,
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
    if location.country == "US"
      5.business_days.before(hire_date + 9.hours).strftime("%b %e, %Y")
    else
      10.business_days.before(hire_date + 9.hours).strftime("%b %e, %Y")
    end
  end
end
