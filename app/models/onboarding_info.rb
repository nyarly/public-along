class OnboardingInfo < ActiveRecord::Base
  validates :employee_id,
            presence: true

  validates_inclusion_of :cw_email, in: [true, false]
  validates_inclusion_of :cw_google_membership, in: [true, false]

  belongs_to :emp_transaction
  belongs_to :employee
end
