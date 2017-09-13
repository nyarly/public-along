class Application < ActiveRecord::Base
  validates :name,
            presence: true

  has_many :access_levels #on_delete cascade in db

  AUTOMATED_OFFBOARDS = ["Google Apps", "CHARM EU", "CHARM JP", "CHARM NA", "OTA", "ROMS"]

  scope :for_emp_transaction, -> (et) { joins(access_levels: :security_profiles).where(['security_profile_id IN (?)', et.security_profiles.pluck("id")])}
end
