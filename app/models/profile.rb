class Profile < ActiveRecord::Base
  validates :start_date,
            presence: true
  validates :end_date,
            presence: true
  validates :department_id,
            presence: true
  validates :location_id,
            presence: true
  validates :worker_type_id,
            presence: true
  validates :job_title_id,
            presence: true
  validates :employee_id,
            presence: true
  validates :adp_employee_id,
            presence: true

  belongs_to :employee
end
