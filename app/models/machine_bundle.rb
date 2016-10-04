class MachineBundle < ActiveRecord::Base
  validates :name,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :description,
            presence: true

  has_many :dept_mach_bundles
  has_many :departments, through: :dept_mach_bundles
end
