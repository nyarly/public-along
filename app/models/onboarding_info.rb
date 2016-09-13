class OnboardingInfo < ActiveRecord::Base
  validates :employee_id,
            presence: true
  validates :buddy_id,
            presence: true

  belongs_to :emp_transaction
  belongs_to :employee
end
