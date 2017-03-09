# Form Model

class SecurityProfileEntry
	include Virtus.model

	extend ActiveModel::Naming
	include ActiveModel::Conversion
	include ActiveModel::Validations

  attr_reader :security_profile

  attribute :name, String
  attribute :description, String
  attribute :department_ids, Array[Integer]
  attribute :access_level_ids, Array[Integer]

  attr_reader :access_level

  attribute :name, String
  attribute :application_id, Integer
  attribute :ad_security_group, String
  attribute :security_profile_ids, Array[Integer]

  # put validations here

  def initialize(attr = {})
    if !attr["id"].nil?
      @security_profile = SecurityProfile.find(attr["id"])

      self[:name] = attr[:name].nil? ? @security_profile.name : attr[:name]
      self[:description] = attr[:description].nil? ? @security_profile.description : attr[:description]
      self[:department_ids] = attr[:department_ids].nil? ? @security_profile.department_ids : attr[:department_ids]
      self[:access_level_ids] = attr[:access_level_ids].nil? ? @security_profile.access_level_ids : attr[:access_level_ids]
    else
      super(attr)
    end
  end

  def security_profile
    @security_profile ||= SecurityProfile.new(
      name: name,
      description: description,
      department_ids: department_ids,
      access_level_ids: access_level_ids
    )
  end

  def access_level
    @access_level ||= AccessLevel.new(
      name: name,
      application_id: application_id,
      ad_security_group: ad_security_group,
      security_profile_ids: security_profile_ids
    )
  end

  def access_levels
    @security_profile.access_levels.build(
      name: name,
      application_id: application_id,
      ad_security_group: ad_security_group,
      security_profile_ids: security_profile_ids
    )
  end

  def build_access_levels
    access_level_ids.each do |al_id|
      security_profile.sec_prof_access_levels.build(
        security_profile_id: security_profile_id,
        access_level_id: al_id
      )
    end
  end

  def errors
    return @errors ||= {}
  end

  def persisted?
    false
  end

  def save
    ActiveRecord::Base.transaction do
      security_profile.save!
    end
  end

end