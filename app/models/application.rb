class Application < ActiveRecord::Base
  validates :name,
            presence: true
  has_many :access_levels, dependent: :destroy

  AUTOMATED_OFFBOARDS = ["Google Apps", "CHARM EU", "CHARM JP", "CHARM NA", "OTA", "ROMS"]
end
