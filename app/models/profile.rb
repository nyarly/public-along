class Profile < ActiveRecord::Base
  include AASM

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

  aasm :column => 'profile_status' do
    state :pending, :initial => true
    state :active
    state :leave
    state :terminated

    event :activate do
      transitions :from => [:pending, :leave], :to => :active
    end

    event :start_leave do
      transitions :from => :active, :to => :leave
    end

    event :terminate do
      transitions :from => :active, :to => :terminated
    end
  end

  scope :regular_worker_type, -> { joins(:worker_type).where(:worker_types => {:kind => "Regular"}) }
  scope :onboarding, -> { where("start_date >= ?", Date.today ) }
  scope :onboarded_this_week, -> { where("start_date BETWEEN ? AND ?", 7.days.ago, Date.today) }
  scope :sort_by_parent_department, -> { joins(:department => :parent_org).order("parent_orgs.name", "departments.name") }

  def downcase_unique_attrs
    self.adp_employee_id = adp_employee_id.downcase if adp_employee_id.present?
  end

  def self.onboarding_group
    where('start_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow)
  end
end
