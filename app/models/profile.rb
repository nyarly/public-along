class Profile < ActiveRecord::Base
  validates :adp_employee_id,
            presence: true
  validates :department_id,
            presence: true
  validates :employee_id,
            presence: true
  validates :job_title_id,
            presence: true
  validates :location_id,
            presence: true
  validates :start_date,
            presence: true
  validates :worker_type_id,
            presence: true

  belongs_to :department
  belongs_to :employee
  belongs_to :job_title
  belongs_to :location
  belongs_to :worker_type
end
