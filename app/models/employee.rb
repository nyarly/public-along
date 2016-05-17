class Employee < ActiveRecord::Base
  validates :first_name,
            presence: true
  validates :last_name,
            presence: true

  attr_accessor :sAMAccountName
  attr_accessor :nearest_time_zone

  def self.activation_group
    where('hire_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow)
  end

  def self.deactivation_group
    where('contract_end_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow)
  end

  def cn
    first_name + " " + last_name
  end

  def dn
    "cn=#{cn}," + ou + BASE
  end

  def ou
    match = OUS.select { |k,v|
      v[:department].include?(cost_center) && v[:country].include?(country)
    }

    if match.length == 1
      match.keys[0]
    else
      puts "WARNING: could not find an exact ou match for #{first_name} #{last_name}; placed in default ou"
      return ""
    end
  end

  def encode_password
    #TODO Replace this with a randomized password that gets sent to the new hire via email/text/???
    "\"123Opentable\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
  end

  def generated_email
    #TODO Some contingent workers should get emails and others shouldn't
    if email.present?
      email
    elsif sAMAccountName.present? && contingent_worker_type.blank?
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

  def full_attrs
    {
      cn: cn,
      objectclass: ["top", "person", "organizationalPerson", "user"],
      givenName: first_name,
      sn: last_name,
      sAMAccountName: sAMAccountName,
      mail: generated_email,
      unicodePwd: encode_password,
      workdayUsername: workday_username,
      co: country,
      accountExpires: generated_account_expires,
      title: business_title,
      description: business_title,
      employeeType: employee_type,
      physicalDeliveryOfficeName: location,
      department: cost_center,
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

  def attrs
    full_attrs.delete_if { |k,v| v.blank? } # AD does not accept nil or empty strings
  end

  def nearest_time_zone
    # US has the broadest time zone spectrum, Pacific time is a sufficient middle ground to capture business hours between NYC and Hawaii
    country == 'US' ? "America/Los_Angeles" : TZInfo::Country.get(country).zone_identifiers.first
  end
end
