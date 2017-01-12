class Department < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :code,
            uniqueness: true,
            case_sensitive: false

  belongs_to :parent_org
  has_many :employees
  has_many :dept_sec_profs, dependent: :destroy
  has_many :security_profiles, through: :dept_sec_profs
  has_many :dept_mach_bundles, dependent: :destroy
  has_many :machine_bundles, through: :dept_mach_bundles

  default_scope { order('name ASC') }
end
