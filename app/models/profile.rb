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

  belongs_to :employee
  belongs_to :department
  belongs_to :job_title
  belongs_to :location
  belongs_to :worker_type

  # scope :active, -> { where(profile_status: 'Active').first }
  # scope :expired, -> { where(profile_status: 'Expired') }
  # scope :pending, -> { where("profiles.start_date >= ?", Date.today).last }
  scope :active_regular, -> { joins(:worker_type).where(:profile_status => "Active", :worker_types => {:kind => "Regular"})}

  def self.active
    where(:profile_status => "Active").last
  end

  def self.pending
    where(:profile_status => "Pending").last
  end

  def self.terminated
    where(:profile_status => "Terminated")
  end

  def downcase_unique_attrs
    self.adp_employee_id = adp_employee_id.downcase if adp_employee_id.present?
  end
end
