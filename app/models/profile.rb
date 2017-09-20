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

  #   aasm :column => 'profile_status' do
  #   state :created, :initial => true
  #   state :pending
  #   state :onboarding
  #   state :active
  #   state :leave
  #   state :offboarding
  #   state :terminated
  # end

  scope :regular_worker_type, -> { joins(:worker_type).where(:worker_types => {:kind => "Regular"})}

  def self.active
    where(:profile_status => "active").last
  end

  def self.pending
    where(:profile_status => "pending").last
  end

  def self.terminated
    where(:profile_status => "terminated").last
  end

  def self.inactive
    where(:profile_status => "leave").last
  end

  def downcase_unique_attrs
    self.adp_employee_id = adp_employee_id.downcase if adp_employee_id.present?
  end
end
