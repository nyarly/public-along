class OffboardingInfo < ActiveRecord::Base
  validates :employee_id,
            presence: true
  validates :forward_email_id,
            presence: true
  validates_inclusion_of :archive_data, in: [true, false]
  validates_inclusion_of :replacement_hired, in: [true, false]

  belongs_to :emp_transaction
  belongs_to :employee
end
