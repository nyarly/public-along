class SecurityProfile < ActiveRecord::Base
  validates :name,
            presence: true

  has_many :dept_sec_profs
  has_many :departments, through: :dept_sec_profs
  has_many :sec_prof_access_levels
  has_many :access_levels, through: :sec_prof_access_levels
  has_many :emp_sec_profiles
  has_many :emp_transactions, through: :emp_sec_profiles

  scope :find_profiles_for, -> (dept_id) { joins(:dept_sec_profs).where(:dept_sec_profs => {department_id: dept_id}) }
end
