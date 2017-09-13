class EmpAccessLevel < ActiveRecord::Base
  validates :access_level_id,
            presence: true
  validates :employee_id,
            presence: true

  belongs_to :access_level
  belongs_to :employee
end
