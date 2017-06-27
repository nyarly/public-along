class Application < ActiveRecord::Base
  validates :name,
            presence: true
  has_many :access_levels #on_delete cascade in db

  AUTOMATED_OFFBOARDS = ["Google Apps", "CHARM EU", "CHARM JP", "CHARM NA", "OTA", "ROMS"]
end
