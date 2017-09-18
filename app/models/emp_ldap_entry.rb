module EmpLdapEntry

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
    if home_address_1.present? && home_address_2.present?
      home_address_1 + ", " + home_address_2
    elsif home_address_1.present?
      home_address_1
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

  def dn
    "cn=#{cn}," + ou + SECRETS.ad_ou_base
  end

  def encode_password
    #TODO Replace this with a randomized password that gets sent to the new hire via email/text/???
    "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT)
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
end
