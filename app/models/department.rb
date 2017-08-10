class Department < ActiveRecord::Base
  validates :name,
            presence: true
  validates :code,
            uniqueness: true,
            case_sensitive: false

  belongs_to :parent_org
  # has_many :employees
  has_many :profiles
  has_many :employees, through: :profiles
  has_many :dept_sec_profs # on_delete, cascade in db
  has_many :security_profiles, through: :dept_sec_profs
  has_many :dept_mach_bundles # on_delete, cascade in db
  has_many :machine_bundles, through: :dept_mach_bundles

  default_scope { order('name ASC') }
end
