class Profile < ActiveRecord::Base
  include AASM

  before_validation :downcase_unique_attrs

  validates :department_id,
            presence: true
  validates :employee,
            presence: true
  validates :job_title_id,
            presence: true
  validates :location_id,
            presence: true
  validates :start_date,
            presence: true
  validates :worker_type_id,
            presence: true

  belongs_to :employee, inverse_of: :profiles
  belongs_to :department
  belongs_to :job_title
  belongs_to :location
  belongs_to :worker_type
  belongs_to :business_unit

  scope :regular_worker_type, -> { joins(:worker_type).where(:worker_types => {:kind => "Regular"}) }
  scope :with_department_id, lambda { |department_ids| where(department_id: [*department_ids]) }
  scope :with_location_id, lambda { |location_ids| where(location_id: [*location_ids]) }
  scope :sorted_by, lambda { |sort_key|
    direction = (sort_key =~ /desc$/) ? 'DESC' : 'ASC'
    case sort_key.to_s
    when /^start_date/
      order("start_date #{direction}")
    end
  }

  aasm :column => 'profile_status' do
    state :pending, :initial => true
    state :active
    state :leave
    state :terminated

    event :activate do
      transitions from: [:pending, :leave, :active], to: :active
    end

    event :start_leave do
      transitions from: [:active, :leave], to: :leave
    end

    event :terminate do
      transitions from: [:terminated, :active, :leave], to: :terminated
    end
  end

  filterrific(
    default_filter_params: { sorted_by: 'start_date_asc' },
    available_filters: [
      :sorted_by,
      :with_department_id,
      :with_location_id
    ]
  )

  def self.options_for_sort
    [
      ['Start date (newest first)', 'start_date_desc'],
      ['Start date (oldest first)', 'start_date_asc']
    ]
  end

  def downcase_unique_attrs
    self.adp_employee_id = adp_employee_id.downcase if adp_employee_id.present?
  end

  def self.onboarding_group
    where('start_date BETWEEN ? AND ?', Date.yesterday, Date.tomorrow)
  end
end
