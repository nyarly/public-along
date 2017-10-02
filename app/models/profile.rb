class Profile < ActiveRecord::Base

  before_validation :downcase_unique_attrs

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

  belongs_to :employee
  belongs_to :department
  belongs_to :job_title
  belongs_to :location
  belongs_to :worker_type

  scope :regular_worker_type, -> { joins(:worker_type).where(:worker_types => {:kind => "Regular"})}

  def self.onboarding_group
    where('start_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow)
  end

  def self.active
    where(:profile_status => "Active").last
  end

  def self.pending
    where(:profile_status => "Pending").last
  end

  def self.terminated
    where(:profile_status => "Terminated").last
  end

  def self.inactive
    where(:profile_status => "Leave").last
  end

  def downcase_unique_attrs
    self.adp_employee_id = adp_employee_id.downcase if adp_employee_id.present?
  end
end
