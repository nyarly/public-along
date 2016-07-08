class Location < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :kind,
            presence: true
  validates :country,
            presence: true
end
