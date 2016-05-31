class XmlTransaction < ActiveRecord::Base
  validates :name,
            presence: true
  validates :checksum,
            presence: true,
            uniqueness: true
end
