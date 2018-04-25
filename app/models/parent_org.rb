class ParentOrg < ActiveRecord::Base
  validates :name,
            presence: true
  validates :code,
            presence: true,
            uniqueness: true,
            case_sensitive: false

  has_many :departments

  scope :name_collection, -> { all.pluck(:name) }
end
