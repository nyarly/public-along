class ParentOrg < ActiveRecord::Base
  validates :name,
            presence: true
  validates :code,
            presence: true,
            uniqueness: true,
            case_sensitive: false

  has_many :departments

  scope :code_collection, -> { all.pluck(:code) }
end
