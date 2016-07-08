class Department < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :code,
            uniqueness: true,
            case_sensitive: false

  has_many :employees
  has_many :dept_sec_profs
  has_many :security_profiles, through: :dept_sec_profs

  default_scope { order('name ASC') }
end
