class AccessLevel < ActiveRecord::Base
  validates :name,
            presence: true
  validates :application_id,
            presence: true

  belongs_to :application
  has_many :sec_prof_access_levels
  has_many :security_profiles, through: :sec_prof_access_levels, dependent: :destroy
  has_many :emp_access_levels,
  has_many :employees, through: :emp_access_levels
end
