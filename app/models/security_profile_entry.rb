# Form Model

class SecurityProfileEntry
	include Virtus.model

	extend ActiveModel::Naming
	include ActiveModel::Conversion
	include ActiveModel::Validations

  attr_accessor :security_profile, :access_level

  attribute :name, String
  attribute :description, String
  attribute :department_ids, Array[Integer]
  attribute :access_level_ids, Array[Integer]

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
    @access_level ||= AccessLevel.new
  end

  def errors
    return @errors ||= {}
  end

  def persisted?
    false
  end

  def save
    if valid?
      ActiveRecord::Base.transaction do
        security_profile.save!
      end
    end
  end

end