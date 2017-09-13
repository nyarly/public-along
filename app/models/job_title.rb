class JobTitle < ActiveRecord::Base
  STATUS = ["Active", "Inactive"]

  validates :code,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :name,
            presence: true
  validates :status,
            presence: true,
            inclusion: { in: STATUS }

  has_many :profiles
  has_many :employees, through: :profiles
end
