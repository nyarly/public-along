class Department < ActiveRecord::Base
  validates :code, uniqueness: true, case_sensitive: false
  validates :name, presence: true

  has_many :approver_designations, as: :approver_designatable, inverse_of: :department, dependent: :destroy
  has_many :dept_mach_bundles, dependent: :destroy
  has_many :dept_sec_profs, dependent: :destroy
  has_many :employees, through: :profiles
  has_many :machine_bundles, through: :dept_mach_bundles
  belongs_to :parent_org
  has_many :profiles, dependent: :nullify
  has_many :security_profiles, through: :dept_sec_profs

  default_scope { order('name ASC') }

  scope :code_collection, -> { where(status: 'Active').pluck(:code) }

  def self.options_for_select
    order('LOWER(name)').map { |e| [e.name, e.id] }
  end
end
