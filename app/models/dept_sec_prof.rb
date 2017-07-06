class DeptSecProf < ActiveRecord::Base
  validates :department_id,
            presence: true
  validates :security_profile_id,
            presence: true

  belongs_to :department
  belongs_to :security_profile
end
