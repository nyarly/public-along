class SecurityProfile < ActiveRecord::Base
  validates :name,
            presence: true

  has_many :dept_sec_profs
  has_many :departments, through: :dept_sec_profs
  has_many :sec_prof_access_levels
  has_many :access_levels, through: :sec_prof_access_levels
end
